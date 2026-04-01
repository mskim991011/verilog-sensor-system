module sr04_ctrl (
    input      clk,
    input      reset,
    input      tick_1,      
    input      start,       
    input      echo,        
    output reg        trig, 
    output reg [8:0]  dist  
);

    localparam IDLE = 2'b00, TRIG = 2'b01, WAIT = 2'b10, CALC = 2'b11;

    localparam integer TIMEOUT_WAIT = 30000; 
    localparam integer TIMEOUT_CALC = 25000; 
    
    reg [1:0]  c_state;
    reg [3:0]  trig_cnt;
    reg [14:0] echo_cnt;
    reg [14:0] timeout_cnt;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            c_state     <= IDLE;
            trig        <= 1'b0;
            dist        <= 9'd0;
            trig_cnt    <= 4'd0;
            echo_cnt    <= 14'd0;
            timeout_cnt <= 15'd0;

        end else begin
            case (c_state)
                IDLE: begin
                    trig        <= 1'b0;
                    trig_cnt    <= 4'd0;
                    echo_cnt    <= 14'd0;
                    timeout_cnt <= 15'd0;

                    if (start) begin  
                        trig    <= 1'b1;
                        c_state <= TRIG;
                    end
                end

                TRIG: begin
                    trig <= 1'b1;
                    if (tick_1) begin
                        if (trig_cnt == 4'd11) begin  
                            trig     <= 1'b0;
                            trig_cnt <= 4'd0;
                            timeout_cnt <= 15'd0;
                            
                            c_state  <= WAIT;
                        end else begin
                            trig_cnt <= trig_cnt + 1;
                        end
                    end
                end
                
                WAIT: begin
                    if (tick_1) begin
                        if(timeout_cnt >= TIMEOUT_WAIT-1) begin
                            dist <= 9'd0;      
                            c_state <= IDLE;
                        end else begin
                            timeout_cnt <= timeout_cnt + 1;
                        end
                    end
                    if (echo) begin           
                        echo_cnt <= 15'd0;
                        timeout_cnt <= 15'd0;
                        c_state <= CALC;
                    end
                end

                CALC: begin
                    if (echo) begin
                        if (tick_1) begin
                            echo_cnt <= echo_cnt + 1;
                            if(timeout_cnt >= TIMEOUT_CALC-1) begin
                                dist <= 9'd0;
                                c_state <= IDLE;
                            end else begin
                                timeout_cnt <= timeout_cnt + 1;
                            end
                        end
                    end else begin
                        
                        dist    <= echo_cnt[14:0] / 58;
                        c_state <= IDLE;
                    end
                end
            endcase
        end
    end

endmodule

module tick_gen_1us (
    input  clk,
    input  reset,
    output reg clk_1us
);

    reg [6:0] count_reg; 

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            count_reg <= 0;
            clk_1us   <= 1'b0;
        end else begin
            if (count_reg == 99) begin
                count_reg <= 0;
                clk_1us   <= 1'b1; 
            end else begin
                count_reg <= count_reg + 1;
                clk_1us   <= 1'b0;
            end
        end
    end
endmodule
