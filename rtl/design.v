module ram #(
    parameter DATA_WIDTH = 32/*Block Size in bits*/, ADDR_WIDTH = 16
)(
    input clk, rst, rd_en, wr_en, 
    input [ADDR_WIDTH-1:0] addr,
    input [DATA_WIDTH-1:0] data_in, 
    output reg [DATA_WIDTH-1:0] data_out,
    output reg valid_out
);

    localparam MEM_DEPTH = 2**ADDR_WIDTH;

    reg [DATA_WIDTH-1:0] mem [0: 256-1];

    always @(posedge clk) begin
        if (rst) begin
            data_out <= {DATA_WIDTH{1'b0}};
            valid_out <= 1'b0;
        end
        else if (wr_en) begin
            mem[addr] <= data_in;
            valid_out <= 1'b0;
        end
        else if (rd_en) begin
            data_out <= mem[addr];
            valid_out<=1'b1;
        end
        else valid_out <=1'b0;
    end
    
endmodule


module cache #(
    parameter WAYS_NUM = 4, 
    parameter SETS_NUM = 64,
    parameter DATA_WIDTH = 32, // MEM_WIDTH
    parameter ADDR_WIDTH = 16, // MEM_ADDR_WIDTH
    parameter MEM_DEPTH = 2**ADDR_WIDTH,
    parameter OFFSET_WIDTH = $clog2(DATA_WIDTH/8), // Byte Adderssing
    parameter INDEX_WIDTH = $clog2(SETS_NUM),
    parameter FULL_WIDTH = $clog2((MEM_DEPTH * DATA_WIDTH) / 8), // CACHE_ADDR_WIDTH
    parameter TAG_WIDTH = FULL_WIDTH - INDEX_WIDTH - OFFSET_WIDTH,
    parameter WAYSEL_WIDTH = $clog2(WAYS_NUM),
    parameter LRU_WIDTH = $clog2(WAYS_NUM)
) (
    input clk, rst, 
//Processor

    input wr_req, rd_req,
    input [FULL_WIDTH-1:0] Paddr, //Processor Addr to Cache
    output hit,

    
    input [DATA_WIDTH-1:0] Pdata_in,
    output reg [DATA_WIDTH-1:0] Pdata_out,

    // Memory 
    input [DATA_WIDTH-1:0] Mdata_in,
    input Mready,
    output reg Mwr_en, Mrd_en,
    output reg [DATA_WIDTH-1:0] Mdata_out,
    output reg [ADDR_WIDTH-1:0] Maddr
);

//============== DEFINES =============
`define TAG FULL_WIDTH-1: (INDEX_WIDTH+OFFSET_WIDTH)
`define INDEX (INDEX_WIDTH+OFFSET_WIDTH)-1: (OFFSET_WIDTH)
//====================================

// ========= STATES ==========
    localparam IDLE=0, READ=1, READ_MM=2, WRITE=3, WRITE_MM = 4;
    reg [2:0] cs, ns;
//=============================

//============= Internal Signals ==================

    // Way
    wire [WAYSEL_WIDTH-1:0] way_sel;
    reg [WAYSEL_WIDTH-1:0] way_sel_r;
    reg [WAYSEL_WIDTH-1:0] hit_way, invalid_way;

    // Cache Controller
    wire [TAG_WIDTH-1:0] tag;
    wire [INDEX_WIDTH-1:0] index;

    // Cache
    reg cache_valid [0:WAYS_NUM-1][0:SETS_NUM-1];
    reg [TAG_WIDTH-1:0] cache_tag [0:WAYS_NUM-1][0:SETS_NUM-1];
    reg [DATA_WIDTH-1:0] cache_data [0:WAYS_NUM-1][0:SETS_NUM-1];
    wire [WAYS_NUM-1:0] way_match;
//==================================================



// --------------------------------------------- CACHE ----------------------------------
// =========== CACHE INITIAL ===========
    integer k,m;
    always @(posedge clk) begin
        if (rst) begin
            
           for (k = 0; k < WAYS_NUM; k = k + 1) begin
                for (m = 0; m < SETS_NUM; m = m + 1) begin
                    cache_valid[k][m] <= 0;
                    cache_tag[k][m] <= 0;
                    cache_data [k][m] <= 0;
                end
            end
        end
    end
//========================================

//=============== DECODE ADDR ===============
assign tag = Paddr[`TAG];
assign index = Paddr[`INDEX];
//===========================================

// ================= WAY & HIT CALCULATION ==============
    genvar i;
    generate
        for (i = 0 ; i < WAYS_NUM ; i = i + 1) begin
            assign way_match[i] = (cache_tag[i][index] == tag) && cache_valid[i][index];
        end
    endgenerate
    assign hit = (cs == READ || cs == WRITE) ? |way_match : 1'b0;
 
    assign  way_sel = (hit) ? hit_way : invalid_way;

    always @(posedge clk) begin
        if (rst)
            way_sel_r <= 0;
        else if (cs == READ && hit)
            way_sel_r <= hit_way;
        else if (cs == READ && !hit)
            way_sel_r <= invalid_way;
        else if (cs == WRITE)
            way_sel_r <= hit_way; // or invalid_way depending on policy
    end
 
    integer j;
    always @(*) begin
        hit_way = {WAYSEL_WIDTH{1'b0}};
        invalid_way = {WAYSEL_WIDTH{1'b0}};
        for(j = 0; j < WAYS_NUM ; j = j + 1) begin
            if (way_match[j] == 1'b1) begin
                hit_way = j[WAYSEL_WIDTH-1:0];
            end 

            if (!cache_valid[j][index] && invalid_way == 0)
                invalid_way = j[WAYSEL_WIDTH-1:0];
        end
    end

//====================================================

// ============= STATE MEMORY ================
    always @(posedge clk) begin
        if (rst)
            cs <= IDLE;
        else 
            cs <= ns;
    end
//============================================
// ============= NEXT STATE LOGIC =============
 always @(*) begin
    case (cs)
        IDLE:     
             if (rd_req) ns = READ;
             else if (wr_req) ns = WRITE;
             else ns = IDLE;
        READ:     
            if (hit) ns = IDLE;
            else ns = READ_MM; 
        READ_MM:  if (Mready) ns = IDLE;
        WRITE:    ns = WRITE_MM;
        WRITE_MM:    ns = IDLE;
        default : ns = IDLE;
    endcase
end


// =============== CACHE LOGIC ==============
    always @(posedge clk) begin
        if (rst) begin
            Pdata_out <= {DATA_WIDTH{1'b0}};
            Mdata_out <= {DATA_WIDTH{1'b0}};
        end
        else if (hit && cs == READ)
            Pdata_out <= cache_data[hit_way][index];
        else if (cs == READ_MM && Mready) begin
                Pdata_out <= Mdata_in;
                cache_data[way_sel_r][index] <= Mdata_in;
                cache_tag[way_sel_r][index]  <= tag;
                cache_valid[way_sel_r][index] <= 1'b1;
        end

        else if (cs == WRITE) begin
                cache_data[way_sel_r][index] <= Pdata_in;
                cache_tag[way_sel_r][index]  <= tag;
                cache_valid[way_sel_r][index] <= 1'b1;
                // Write Through
                Mdata_out <= Pdata_in;
        end
    end


    always @(posedge clk) begin
        if(rst) begin
            Maddr <= {ADDR_WIDTH{1'b0}};
            Mrd_en <= 1'b0;
            Mwr_en <= 1'b0;
        end else begin
            if (cs == READ && !hit) begin
                Mrd_en <= 1'b1;
                Maddr <= {tag, index};
            end else if (cs == WRITE) begin
                Mwr_en <= 1'b1;
                Maddr <= {tag, index};
            end
            else begin
                Mrd_en <= 1'b0;
                Mwr_en <= 1'b0;
            end

            
        end
    end
//===================================================
endmodule