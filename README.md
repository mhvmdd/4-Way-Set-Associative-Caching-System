4-Way Set Associative Cache System
==================================

A parameterized memory hierarchy system designed in Verilog HDL, consisting of Main Memory (RAM), a 4-way set-associative cache, and a cache controller. This project was developed as part of the **CSE311s: Computer Architecture** course at Ain Shams University.

📝 Project Overview
-------------------

The system models a generic digital system that issues read and write requests to memory. Requests are first handled by a cache subsystem designed to reduce average memory access time. If the data is not present in the cache (a miss), it is fetched from main memory. A cache controller manages all coordination between the cache and main memory, ensuring data correctness and proper replacement behavior.

✨ Key Features
--------------

*   **Parameterized Design:** Both the RAM and Cache modules are fully parameterized, allowing for reusable and scalable configurations (address width, data width, number of sets/ways).
    
*   **4-Way Set Associative Mapping:** Flexible cache mapping reducing conflict misses compared to direct-mapped caches.
    
*   **Write-Through Policy:** Ensures data consistency between the cache and main memory on every write hit.
    
*   **Custom Replacement Policy:** Prioritizes filling invalid/empty cache lines first; if all ways are valid, it defaults to replacing Way 0.
    
*   **FSM-Based Controller:** A robust finite state machine managing hit/miss logic, memory fetching, and write-backs.
    

🏗️ System Architecture
-----------------------

The system is composed of three primary modules:

### 1\. RAM Module (Main Memory)

*   Synchronous read and write operations.
    
*   Fully parameterized for varying data and address sizes.
    
*   Only accessed by the cache controller during a cache miss (read) or a write-through operation (write).
    

### 2\. Cache Module

*   Configurable number of sets, ways, tag width, and data width.
    
*   Stores data, tags, and valid bits for each cache line.
    
*   4-way set associativity.
    

### 3\. Cache Controller

*   Decodes incoming memory addresses into **Tag** and **Index** segments.
    
*   Checks all ways in the indexed set for a cache hit.
    
*   **Read Hit:** Returns data directly from the cache.
    
*   **Read Miss:** Fetches data from RAM, updates the cache, and returns data to the processor.
    
*   **Write Hit:** Writes data to the cache and simultaneously updates main memory (Write-Through).
    
*   **Write Miss:** Writes data directly to main memory and allocates the block in the cache.
    

📐 Testbench Configuration
--------------------------

The default testbench (tb\_cache\_system.v) simulates the system using the following specifications:

*   **Memory Address:** 16 bits
    
*   **Memory Data:** 32 bits
    
*   **Cache Type:** 4-way set associative
    
*   **Cache Entry Data Size:** 32 bits
    
*   **Total Number of Cache Entries:** 256 (64 sets × 4 ways)
    

### Address Breakdown (16-bit)

*   **Offset:** 2 bits (32-bit word = 4 bytes)
    
*   **Index:** 6 bits (64 sets)
    
*   **Tag:** 8 bits
    

🖥️ Simulation & Waveforms
--------------------------

The testbench verifies the following critical scenarios:

### 1\. Reset

When the reset signal is asserted, all output signals and cache valid bits are driven to zero.

### 2\. Read Miss (No Hit)

*   The processor sends a read request that misses the cache.
    
*   The controller transitions from READ to READ\_MM (Read Main Memory).
    
*   The requested address is sent to RAM.
    
*   After one cycle, the data from RAM is output to the processor and stored in the cache.
    

### 3\. Write Hit

*   The processor sends a write request to an address currently in the cache.
    
*   The data is written to the matching cache way.
    
*   Simultaneously, the data is written to Main Memory following the **write-through** policy.
    

### 4\. Write Miss

*   The processor sends a write request to an address not in the cache.
    
*   The controller allocates a random/invalid way in the cache for the new tag and data.
    
*   Data is written to Main Memory.
    

### 5\. Read Hit

*   The processor sends a read request to an address currently in the cache.
    
*   Data is output directly from the cache to the processor with zero wait states (faster than the miss scenario).
    

🛠️ How to Run
--------------

1.  git clone https://github.com/mhvmdd/4-Way-Set-Associative-Caching-System.git
    
2.  Open the project in your preferred HDL simulator (e.g., Siemens QuestaSim, Xilinx Vivado).
    
3.  Compile **design.v** and **tb\_cache\_system.v**.
    
4.  Simulate the testbench and inspect the waveform to observe hit/miss behaviors and state transitions.
    

👥 Team Members
---------------

*   **Mohammed Yasser Said** 
    
*   **Farah Hiatham Saddik** 
    
*   **Mohamed Ahmed Shehata** 
    

📄 Course Information
---------------------

*   **Course:** CSE311s: Computer Architecture
    
*   **Institution:** Faculty of Engineering, Ain Shams University
