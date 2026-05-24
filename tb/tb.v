module tb;
	    // Parameters
    localparam DATA_WIDTH = 32;
    localparam ADDR_WIDTH = 16;
    localparam WAYS_NUM = 4;
    localparam SETS_NUM = 64;
    parameter MEM_DEPTH = 2**ADDR_WIDTH;
    parameter OFFSET_WIDTH = $clog2(DATA_WIDTH/8); // Byte Adderssing
    parameter INDEX_WIDTH = $clog2(SETS_NUM);
    parameter FULL_WIDTH = $clog2((MEM_DEPTH * DATA_WIDTH) / 8); // CACHE_ADDR_WIDTH
    parameter TAG_WIDTH = FULL_WIDTH - INDEX_WIDTH - OFFSET_WIDTH;
    parameter WAYSEL_WIDTH = $clog2(WAYS_NUM);
    parameter LRU_WIDTH = $clog2(WAYS_NUM);
    // Clock and Reset
    reg clk;
    reg rst;

    // Processor signals
    reg wr_req, rd_req;
    reg [FULL_WIDTH-1:0] Paddr;
    reg [ADDR_WIDTH-1:0] Tempaddr;
    reg [DATA_WIDTH-1:0] Pdata_in;
    wire [DATA_WIDTH-1:0] Pdata_out;
    wire hit;

    // Memory interface
    wire Mwr_en, Mrd_en;
    wire [ADDR_WIDTH-1:0] Maddr;
    wire [DATA_WIDTH-1:0] Mdata_in;
    wire [DATA_WIDTH-1:0] Mdata_out;
    wire Mready;

    // Clock generation
    initial begin
	 	clk = 0;
	 	forever #1 clk = ~clk;	
    end
   
reg [DATA_WIDTH-1:0] mem_temp [0: MEM_DEPTH-1];
    // Instantiate RAM
    ram #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_ram (
        .clk(clk),
        .rst(rst),
        .rd_en(Mrd_en),
        .wr_en(Mwr_en),
        .addr(Maddr),
        .data_in(Mdata_out),
        .data_out(Mdata_in),
        .valid_out(Mready)
    );

    // Instantiate Cache
    cache #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .WAYS_NUM(WAYS_NUM),
        .SETS_NUM(SETS_NUM)
    ) u_cache (
        .clk(clk),
        .rst(rst),
        .wr_req(wr_req),
        .rd_req(rd_req),
        .Paddr(Paddr),
        .Pdata_in(Pdata_in),
        .Pdata_out(Pdata_out),
        .hit(hit),
        .Mdata_in(Mdata_in),
        .Mready(Mready),
        .Mwr_en(Mwr_en),
        .Mrd_en(Mrd_en),
        .Mdata_out(Mdata_out),
        .Maddr(Maddr)
    );

    integer i,  error, correct;

    initial begin
    	$readmemh ("mem.dat", u_ram.mem);
    	$readmemh ("mem.dat", mem_temp);
    	error = 0;
    	correct = 0;

		// rst 
		rst = 1;
		Paddr = 0;
		Pdata_in = 0;
		wr_req = 0;
		rd_req = 0;
		@(negedge clk);

		// read
		rst = 0;
		wr_req = 0;
		for (i = 0 ; i < 100 ; i = i + 1) begin
			Tempaddr = $urandom_range(0,255);
			Paddr = Tempaddr << 2;
			Pdata_in = $random;
			rd_req = 1;
			repeat (2)@(negedge clk);
			rd_req = 0;
			repeat (2)@(negedge clk);
			if (Pdata_out != mem_temp[Tempaddr]) begin
				$display($time, "    Actual Out (Pout = %h) != Expected Out = (Expected = %h)", Pdata_out, mem_temp[Tempaddr]);
				error = error + 1;
			end
			else correct = correct + 1;
		end		
		// Write
		rst = 0;
		rd_req = 0;
		for (i = 0 ; i < 100 ; i = i + 1) begin
			Tempaddr = $urandom_range(0,255);
			Paddr = Tempaddr << 2;
			Pdata_in = $random;
			wr_req = 1;
			repeat (2)@(negedge clk);
			wr_req = 0;
			repeat (2)@(negedge clk);
		end



		rst = 0;
		wr_req = 0;
		for (i = 0 ; i < 100 ; i = i + 1) begin
			Tempaddr = $urandom_range(0,255);
			Paddr = Tempaddr << 2;
			Pdata_in = $random;
			rd_req = 1;
			repeat (2)@(negedge clk);
			rd_req = 0;
			repeat (2)@(negedge clk);
		end
		$stop;
	end
endmodule 