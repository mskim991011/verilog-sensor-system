`timescale 1ns / 1ps

module sensor_top (
    input clk,
    input reset,
    input sw_mode,
    input echo,
    output trig,
    inout dhtio,
    output [7:0] fnd_data,
    output [3:0] fnd_digit
);


    wire w_tick_1us;
    wire [8:0] w_dist;


    reg [23:0] sr04_auto_cnt;
    reg r_sr04_start;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            sr04_auto_cnt <= 0;
            r_sr04_start  <= 0;
        end else begin

            if (sr04_auto_cnt >= 10_000_000 - 1) begin
                sr04_auto_cnt <= 0;
                r_sr04_start  <= 1'b1;
            end else begin
                sr04_auto_cnt <= sr04_auto_cnt + 1;
                r_sr04_start  <= 1'b0;
            end
        end
    end



    tick_gen_1us U_TICK_SR04 (
        .clk(clk),
        .reset(reset),
        .clk_1us(w_tick_1us)
    );

    sr04_ctrl U_SR04 (
        .clk(clk),
        .reset(reset),
        .tick_1(w_tick_1us),
        .start(r_sr04_start),
        .echo(echo),
        .trig(trig),
        .dist(w_dist)
    );

    wire [15:0] w_humi;
    wire [15:0] w_temp;
    wire w_dht_valid;
    wire w_dht_done;

    reg [27:0] dht_auto_cnt; 
    reg r_dht_start;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            dht_auto_cnt <= 0;
            r_dht_start  <= 0;
        end else begin
            if (dht_auto_cnt >= 200_000_000 - 1) begin
                dht_auto_cnt <= 0;
                r_dht_start  <= 1'b1; 
            end else begin
                dht_auto_cnt <= dht_auto_cnt + 1;
                r_dht_start  <= 1'b0;
            end
        end
    end

    dht11_controller U_DHT11 (
        .clk(clk),
        .reset(reset),
        .start(r_dht_start),
        .ht(w_humi),
        .temp(w_temp),
        .dht11_done(w_dht_done),
        .dht11_valid(w_dht_valid),
        .dhtio(dhtio)
    );

    
    reg  [15:0] final_fnd_value;
    wire [3:0] d_1m = (w_dist / 100) % 10;
    wire [3:0] d_10cm = (w_dist % 100) / 10;
    wire [3:0] d_1cm = (w_dist % 100) % 10;

    wire [7:0] t_val = w_temp[15:8];
    wire [7:0] h_val = w_humi[15:8];
    wire [3:0] t_10 = t_val / 10;
    wire [3:0] t_1 = t_val % 10;
    wire [3:0] h_10 = h_val / 10;
    wire [3:0] h_1 = h_val % 10;


    always @(*) begin
        if (sw_mode == 1'b0) begin
            final_fnd_value = {4'd0, d_1m, d_10cm, d_1cm};
        end else begin
            final_fnd_value = {t_10, t_1, h_10, h_1};
        end
    end

    fnd_contr U_FND (
        .clk(clk),
        .reset(reset),
        .value(final_fnd_value),
        .fnd_digit(fnd_digit),
        .fnd_data(fnd_data)
    );

endmodule
