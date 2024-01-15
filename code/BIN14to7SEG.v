module add4(in, out);
  input [3:0] in;
  output [3:0] out;
  reg [3:0] out;

  always @ (in)
    case (in)
      4'b0000: out <= 4'b0000;
      4'b0001: out <= 4'b0001;
      4'b0010: out <= 4'b0010;
      4'b0011: out <= 4'b0011;
      4'b0100: out <= 4'b0100;
      4'b0101: out <= 4'b1000;
      4'b0110: out <= 4'b1001;
      4'b0111: out <= 4'b1010;
      4'b1000: out <= 4'b1011;
      4'b1001: out <= 4'b1100;
      default: out <= 4'b0000;
    endcase
endmodule

module BIN14toBCD4(CLK, RSTn, BIN, THOUSANDS, HUNDREDS, TENS, ONES);
  input CLK;
  input RSTn;
  input [13:0] BIN;
  output [3:0] THOUSANDS, HUNDREDS, TENS, ONES;

  wire [3:0] c1, c2, c3, c4, c5, c6, c7;
  wire [3:0] d1, d2, d3, d4, d5, d6, d7;

  assign d1 = BIN[13:10];
  assign d2 = {c1[2:0], BIN[9]};
  assign d3 = {c2[2:0], BIN[8]};
  assign d4 = {c3[2:0], BIN[7]};
  assign d5 = {c4[2:0], BIN[6]};
  assign d6 = {1'b0, c1[3], c2[3], c3[3]};
  assign d7 = {c6[2:0], c4[3]};

  add4 m1(d1, c1);
  add4 m2(d2, c2);
  add4 m3(d3, c3);
  add4 m4(d4, c4);
  add4 m5(d5, c5);
  add4 m6(d6, c6);
  add4 m7(d7, c7);

  assign THOUSANDS = c5;
  assign HUNDREDS = c6;
  assign TENS = c7;
  assign ONES = BIN[3:0];
endmodule

module BIN14to7SEG4(CLK, RSTn, counter, SEG7OUT, SEG7COM);
  input CLK;
  input RSTn;
  input [7:0] counter; // Assuming 8-bit counter for this example
  output [6:0] SEG7OUT;
  output [3:0] SEG7COM;

  wire [3:0] THOUSANDS, HUNDREDS, TENS, ONES;

  // BIN14toBCD4モジュールを利用して、counterを4桁のBCDに変換
  BIN14toBCD4 bin14tobcd4(CLK, RSTn, counter, THOUSANDS, HUNDREDS, TENS, ONES);

  reg [17:0] prescaler_7seg; // 7seg display prescaler
  wire carryout_7seg; // switch display
  reg [1:0] counter_7seg;

  function [3:0] select7segcom;
    input [1:0] counter_7seg;
    case (counter_7seg)
      default: select7segcom = 4'b1111;
      2'b00: select7segcom = 4'b1110;
      2'b01: select7segcom = 4'b1101;
      2'b10: select7segcom = 4'b1011;
    endcase
  endfunction

  // 4桁の7セグメントディスプレイを制御
  always @ (posedge CLK or negedge RSTn) begin
    if (RSTn == 1'b0) begin
      prescaler_7seg <= 18'b0;
      counter_7seg <= 2'b00;
    end
    else if (prescaler_7seg == 18'd50000) begin
      prescaler_7seg <= 18'b0;
      counter_7seg <= (counter_7seg == 2'b10) ? 2'b00 : counter_7seg + 1;
    end
    else begin
      prescaler_7seg <= prescaler_7seg + 1;
    end
  end

  // セグメントの選択信号
  assign SEG7COM = select7segcom(counter_7seg);

  // 各桁の7セグメントディスプレイの出力
  always @*
    case (select7segcom)
      4'b1110: SEG7OUT = get7segcode(THOUSANDS);
      4'b1101: SEG7OUT = get7segcode(HUNDREDS);
      4'b1011: SEG7OUT = get7segcode(TENS);
      default: SEG7OUT = get7segcode(ONES);
    endcase

  // 7セグメントのコードを返す関数
  function [6:0] get7segcode;
    input [3:0] bcd;
    case (bcd)
      4'b0000: get7segcode = 7'b1000000; // 0
      4'b0001: get7segcode = 7'b1111001; // 1
      4'b0010: get7segcode = 7'b0100100; // 2
      4'b0011: get7segcode = 7'b0110000; // 3
      4'b0100: get7segcode = 7'b0011001; // 4
      4'b0101: get7segcode = 7'b0010010; // 5
      4'b0110: get7segcode = 7'b0000010; // 6
      4'b0111: get7segcode = 7'b1111000; // 7
      4'b1000: get7segcode = 7'b0000000; // 8
      4'b1001: get7segcode = 7'b0010000; // 9
      default: get7segcode = 7'b1111111; // Off
    endcase
  endfunction

endmodule