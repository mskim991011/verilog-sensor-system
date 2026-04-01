`timescale 1ns / 1ps

module fnd_contr (
    input clk,
    input reset,
    input [15:0] value,
    output reg [3:0] fnd_digit,
    output reg [7:0] fnd_data
);

    reg [16:0] cnt;
    reg [ 1:0] number;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            cnt <= 0;
            number <= 0;
        end else begin

            if (cnt >= 99_999) begin
                cnt <= 0;
                number <= number + 1;
            end else begin
                cnt <= cnt + 1;
            end
        end
    end


    reg [3:0] value_place;

    always @(*) begin
        case (number)
            2'b00: begin
                fnd_digit   = 4'b1110;
                value_place = value[3:0];
            end
            2'b01: begin
                fnd_digit   = 4'b1101;
                value_place = value[7:4];
            end
            2'b10: begin
                fnd_digit   = 4'b1011;
                value_place = value[11:8];
            end
            2'b11: begin
                fnd_digit   = 4'b0111;
                value_place = value[15:12];
            end
            default: begin
                fnd_digit   = 4'b1111;
                value_place = 4'h0;
            end
        endcase
    end


    always @(*) begin
        case (value_place)
            4'h0: fnd_data = 8'hC0;
            4'h1: fnd_data = 8'hF9;
            4'h2: fnd_data = 8'hA4;
            4'h3: fnd_data = 8'hB0;
            4'h4: fnd_data = 8'h99;
            4'h5: fnd_data = 8'h92;
            4'h6: fnd_data = 8'h82;
            4'h7: fnd_data = 8'hF8;
            4'h8: fnd_data = 8'h80;
            4'h9: fnd_data = 8'h90;
            default: fnd_data = 8'hFF;
        endcase
    end

endmodule
