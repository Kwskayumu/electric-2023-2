//1月22日．得点が入るようになった．
module ziyuukadai3(CLK,RSTn,button1,LEDout,SEG7OUT,SEG7COM);
input CLK;
input RSTn;
//input [3:0] PUSH;
input wire [4:0] button1; 
reg [9:0] regbut1;


output [9:0] LEDout;
output [6:0] SEG7OUT;
output [3:0] SEG7COM;

reg[1:0] is_counted;


reg [9:0] ledout;
reg [3:0] bar1;
reg [3:0] bar2;
reg [3:0] ballx;
reg [4:0] bally;


reg [9:0] ball_mdf;


reg [1:0] wall;
reg [1:0] is_ball_up;
reg [2:0] ball_angle; // ボールの角度．0は45度，1は90度，2は135度
reg [21:0] prescaler;
reg [30:0] prescaler_ball;
reg [6:0] color;
reg [1:0] regrotA;   //rotary encoder phase A rising
reg [1:0] regpush0;
reg [1:0] regpush1;
reg [1:0] regpush2;
reg [1:0] regpush3;


reg [13:0] counter;


parameter PRESCALER_VALUE = 22'd2000; // デフォルトの値を定義
parameter PRESCALER_BALL_VALUE = 31'd4000000; // デフォルトの値を定義
parameter LEFT_MOST = 4'b0000;
parameter RIGHT_MOST = 4'b1111;
parameter UP_MOST = 5'b00000;
parameter DOWN_MOST = 5'b11111;
parameter BAR1_Y = 5'b00011;
parameter BAR2_Y = 5'b11100;
parameter LENGTH_OF_BAR = 3'b011; // バーの長さ．固定で頼む

wire carryout;
   // 多分バーの移動のプリスケーラ
   always @ (posedge CLK or negedge RSTn)  begin  
       if(RSTn == 1'b0)
           prescaler <= 22'b0;
       else if(prescaler == PRESCALER_VALUE)
           prescaler <= 22'b0;
       else
           prescaler <= prescaler + 1;
   end
   assign    carryout = (prescaler == PRESCALER_VALUE) ? 1'b1 : 1'b0;


   // ボールの移動のプリスケーラ
   always @ (posedge CLK or negedge RSTn)  begin  
       if(RSTn == 1'b0)
           prescaler_ball <= 31'b0;
       else if(prescaler_ball == PRESCALER_BALL_VALUE)
           prescaler_ball <= 31'b0;
       else
           prescaler_ball <= prescaler_ball + 1;
   end
   assign    carryout_ball = (prescaler_ball == PRESCALER_BALL_VALUE) ? 1'b1 : 1'b0;


   // colorと呼ぶのは相応しくないかも．コード後半で表示時間を管理する時に使うカウンタ
   always @ (posedge CLK)  begin  
       if (carryout == 1'b1)   begin
           if (color == 7'b1111111)
               color <= 7'b0;
           else
               color <= color + 1;
       end
   end


   // バー1の移動
   always @ (posedge CLK or negedge RSTn)  begin  
       // 初期化
       if (RSTn == 1'b0)   begin
           bar1 <= LEFT_MOST;
           regpush1 [1:0] <= 2'b0;
           regpush0 [1:0] <= 2'b0;
       end
       else if (carryout)  begin  
			regbut1[1] <= regbut1[0];
			regbut1[0] <= button1[0];
			regbut1[3] <= regbut1[2];
			regbut1[2] <= button1[1];
			// regbut1[5] <= regbut1[4];
			// regbut1[4] <= button1[2];			
           if (regbut1[1:0] == 2'b01 && (!((is_ball_up == 1) && (bally == BAR1_Y) && ((ballx >= bar1) && (ballx <= bar1 + (LENGTH_OF_BAR - 1))))))    begin // 多分，ボールがやってきてバーにぶつかった時には動かないようにする
               if (bar1 == LEFT_MOST) // 左端ならば
                   bar1 <= bar1; // そのまま
               else
                   bar1 <= bar1 - 3'b1; // 端じゃなければ左に移動
           end
           else if (regbut1[3:2] == 2'b01 && (!((is_ball_up == 1) && (bally == BAR1_Y) && ((ballx >= bar1) && (ballx <= bar1 + (LENGTH_OF_BAR - 1))))))   begin // 多分，ボールがやってきてバーにぶつかった時には動かないようにする
               if (bar1 == RIGHT_MOST - LENGTH_OF_BAR + 1) // 右端ならば
                   bar1 <= bar1; // そのまま
               else
                   bar1 <= bar1 + 3'b1; // 端じゃなければ右に移動
           end
           else
               bar1 <= bar1; // 多分，ボールがやってきてバーにぶつかった時には動かないようにする
       end
   end


   // バー2の移動
   always @ (posedge CLK or negedge RSTn)  begin  
       if (RSTn == 1'b0)   begin
           bar2 <= RIGHT_MOST - LENGTH_OF_BAR + 1;
           regpush3 [1:0] <= 2'b0;
           regpush2 [1:0] <= 2'b0;
       end
       else if (carryout)  begin
			regbut1[7] <= regbut1[6];
			regbut1[6] <= button1[3];
			regbut1[9] <= regbut1[8];
			regbut1[8] <= button1[4];	
           if (regbut1[7:6] == 2'b01 && (!((is_ball_up == 0) && (bally == BAR2_Y) && ((ballx >= bar2) && (ballx <= bar2 + (LENGTH_OF_BAR - 1))))))    begin // 多分，ボールがやってきてバーにぶつかった時には動かないようにする
               if (bar2 == LEFT_MOST) // 左端ならば
                   bar2 <= bar2; // そのまま
               else
                   bar2 <= bar2 - 3'b1; // 端じゃなければ左に移動
           end
           else if (regbut1[9:8] == 2'b01 && (!((is_ball_up == 0) && (bally == BAR2_Y) && ((ballx >= bar2) && (ballx <= bar2 + (LENGTH_OF_BAR - 1))))))   begin // 多分，ボールがやってきてバーにぶつかった時には動かないようにする
               if (bar2 == RIGHT_MOST - LENGTH_OF_BAR + 1) // 右端ならば
                   bar2 <= bar2; // そのまま
               else
                   bar2 <= bar2 + 3'b1; // 端じゃなければ右に移動
           end
           else
               bar2 <= bar2; // 多分，ボールがやってきてバーにぶつかった時には動かないようにする
       end
   end
  
   // ボールの移動
   // 10bit up counter that counts up at carryout = 1;
   always @ (posedge CLK or negedge RSTn)  begin  
       // 初期化
       if(RSTn == 1'b0)    begin
        //    counter <= 0;
           bally <= BAR1_Y; // ボールの初期位置は今後変更すべき
           ballx <= bar2;
           is_ball_up <= 0;
           ball_angle <= 1;
			  is_counted <= 0;
       end
       else if(is_ball_up == 1 && bally == BAR1_Y && ballx == ((ballx >= bar1) && (ballx <= bar1 + (LENGTH_OF_BAR - 1)))) begin // ボールがやってきてバー1にぶつかった時には
           // is_ball_up(ボールの方向)のみ逆転させる
           ballx <= ballx;
           bally <= bally;
           is_ball_up <= 0;
           if(ballx == bar1)
               ball_angle <= 2;
           else if(ballx == bar1 + 1)
               ball_angle <= 1;
           else if(ballx == bar1 + 2)
               ball_angle <= 0;
       end
       else if(is_ball_up == 0 && bally == BAR2_Y && ballx == ((ballx >= bar2) && (ballx <= bar2 + (LENGTH_OF_BAR - 1))))  begin // ボールがやってきてバー2にぶつかった時は
           // is_ball_up(ボールの方向)のみ逆転させる   
           ballx <= ballx;
           bally <= bally;
           is_ball_up <= 1;
           if(ballx == bar2)
               ball_angle <= 2;
           else if(ballx == bar2 + 1)
               ball_angle <= 1;
           else if(ballx == bar2 + 2)
               ball_angle <= 0;

       end
       else if(is_ball_up == 0)    begin // is_ball_upが0で，バーにぶつかっていない時
           if(bally == DOWN_MOST && carryout_ball == 1'b1)   begin // 画面の端ならば
               // 止まる
               ballx <= ballx;
               bally <= bally;
					if(is_counted == 0) begin
						counter <= counter + 1;
						is_counted <= 1;
					end
           end
           else if(carryout_ball == 1'b1)      begin  
               if(ball_angle == 0) begin
                   if(ballx == RIGHT_MOST || ballx == LEFT_MOST ) begin
                       ballx <= ballx - 3'b1;
                       bally <= bally + 3'b1;
                       ball_angle <= 2;
                   end
                   else begin
                       ballx <= ballx + 3'b1;
                       bally <= bally + 3'b1;
                       ball_angle <= ball_angle;
                   end
               end
               else if(ball_angle == 1) begin
                   ballx <= ballx;
                   bally <= bally + 3'b1;
               end
               else if(ball_angle == 2) begin
                   if(ballx == RIGHT_MOST || ballx == LEFT_MOST ) begin
                       ballx <= ballx + 3'b1;
                       bally <= bally + 3'b1;
                       ball_angle <= 0;
                   end
                   else begin
                       ballx <= ballx - 3'b1;
                       bally <= bally + 3'b1;
                       ball_angle <= ball_angle;
                   end
               end
              
           end
           else   
               bally <= bally; // carryout_ballが切りかわらるまで止まり続ける=carryout_ballがボールのスピードを決めている
       end 
       else if(is_ball_up == 1)        begin // is_ball_upが1で，バーにぶつかっていない時
           if(bally == DOWN_MOST && carryout_ball == 1'b1)     begin // 画面の端ならば
               // 止まる
               ballx <= ballx;
               bally <= bally;
					if(is_counted == 0) begin
						counter <= counter + 100;
						is_counted <= 1;
					end
           end
           else if(carryout_ball == 1'b1)  begin    // 普通は
               if(ball_angle == 0) begin
                   if(ballx == RIGHT_MOST || ballx == LEFT_MOST ) begin
                       ballx <= ballx - 3'b1;
                       bally <= bally - 3'b1;
                       ball_angle <= 2;
                   end
                   else begin
                       ballx <= ballx + 3'b1;
                       bally <= bally - 3'b1;
                       ball_angle <= ball_angle;
                   end
               end
               else if(ball_angle == 1) begin
                   ballx <= ballx;
                   bally <= bally - 3'b1;
               end
               else if(ball_angle == 2) begin
                   if(ballx == RIGHT_MOST || ballx == LEFT_MOST ) begin
                       ballx <= ballx + 3'b1;
                       bally <= bally - 3'b1;
                       ball_angle <= 0;
                   end
                   else begin
                       ballx <= ballx - 3'b1;
                       bally <= bally + 3'b1;
                       ball_angle <= ball_angle;
                   end
               end
           end
           else       
               bally <= bally; // carryout_ballが切りかわるまで止まり続ける=carryout_ballがボールのスピードを決めている
       end 
   end


   // 10bit up counter that counts up at carryout = 1;
   always @ (posedge CLK or negedge RSTn)  begin  
       if (RSTn == 1'b0)    begin
           ball_mdf <= 10'b1000000000;
		 end
       else if (bally < 5'b10000) begin
           ball_mdf <= 10'b0000000000 + 8'b11110000 - ballx *5'b10000 +  bally;
       end
       else if (bally >= 5'b10000) begin
           ball_mdf <= 10'b0100000000 + ballx *5'b10000  + 5'b11111 - bally;
       end
   end


   // 10bit up ledout that counts up at carryout = 1;
   always @ (posedge CLK or negedge RSTn) 
       case(color)
           // バー1の表示
           // 長さに応じて表示を変える必要がある
           7'b0000000: ledout <= 10'b0000000010 + 8'b11110000 - bar1*5'b10000;
           7'b0000001: ledout <= 10'b0000000010 + 8'b11110000 - bar1*5'b10000 - 5'b10000;
           7'b0000010: ledout <= 10'b0000000010 + 8'b11110000 - bar1*5'b10000 - 6'b100000;


           // バー2の表示
           7'b0000011: ledout <= 10'b0100000010 + bar2*5'b10000;
           7'b0000100: ledout <= 10'b0100000010 + bar2*5'b10000 + 5'b10000;
           7'b0000110: ledout <= 10'b0100000010 + bar2*5'b10000 + 6'b100000;


           // ボールの表示
           7'b0111000: ledout <= ball_mdf;
           7'b0111001: ledout <= ball_mdf;
           7'b0111010: ledout <= ball_mdf;
          
           default : ledout <= 10'b1000000000;     
       endcase
              
   assign LEDout[9:0] = ledout;
// 多分これはまだ使っていない
BIN14to7SEG4 binto7seg4 (CLK,RSTn,counter,SEG7OUT,SEG7COM);
// 7セグメントの表示
endmodule