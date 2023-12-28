module ziyuukadai3(CLK,RSTn, PUSH,LEDout,SEG7OUT,SEG7COM);
input CLK;
input RSTn;
input [3:0] PUSH;

output [9:0] LEDout;
output [6:0] SEG7OUT;
output [3:0] SEG7COM;

reg [9:0] ledout;
reg [2:0] bar1;
reg [2:0] bar2;
reg [2:0] ballx;
reg [3:0] bally;

reg [1:0] wall;
reg [1:0] is_ball_up;
reg [21:0] prescaler;
reg [30:0] prescaler_ball;
reg [6:0] color;
reg [1:0] regrotA;   //rotary encoder phase A rising
reg [1:0] regpush0;
reg [1:0] regpush1;
reg [1:0] regpush2;
reg [1:0] regpush3;

reg [9:0] counter;

parameter PRESCALER_VALUE = 22'd2000; // デフォルトの値を定義
parameter PRESCALER_BALL_VALUE = 31'd4000000; // デフォルトの値を定義
parameter LEFT_MOST = 3'b000;
parameter RIGHT_MOST = 3'b111;
parameter UP_MOST = 4'b0000;
parameter DOWN_MOST = 4'b1111;
parameter BAR1_Y = 4'b1100;
parameter BAR2_Y = 4'b0011;
parameter LENGTH_OF_BAR = 3'b011;

wire carryout;
	// 多分バーの移動のプリスケーラ
    always @ (posedge CLK or negedge RSTn) 	begin	
        if(RSTn == 1'b0) 	begin	
            prescaler <= 22'b0;
		  end
        else if(prescaler == PRESCALER_VALUE) 
            prescaler <= 22'b0;
        else
            prescaler <= prescaler + 1;
    end
    assign    carryout = (prescaler == PRESCALER_VALUE) ? 1'b1 : 1'b0;

	// ボールの移動のプリスケーラ
	always @ (posedge CLK or negedge RSTn) 	begin	
        if(RSTn == 1'b0) 		begin
            prescaler_ball <= 31'b0;
		end
        else if(prescaler_ball == PRESCALER_BALL_VALUE)
            prescaler_ball <= 31'b0;
        else
            prescaler_ball <= prescaler_ball + 1;
    end
    assign    carryout_ball = (prescaler_ball == PRESCALER_BALL_VALUE) ? 1'b1 : 1'b0;

	// colorと呼ぶのは相応しくないかも．コード後半で表示時間を管理する時に使うカウンタ
    always @ (posedge CLK) 	begin	
		  if (carryout == 1'b1) 		begin
			  if (color == 7'b1111111)
			     color <= 7'b0;
			  else
			     color <= color + 1;
		  end
    end

    // バー1の移動
	always @ (posedge CLK or negedge RSTn) 	begin	
		// 初期化
		if (RSTn == 1'b0) 		begin 
			bar1 <= LEFT_MOST;
			regpush1 [1:0] <= 2'b0;
			regpush0 [1:0] <= 2'b0;
		end
		else if (carryout) 	begin	
			regpush1[1] <= regpush1[0];
			regpush1[0] <= PUSH[1];
			regpush0[1] <= regpush0[0];
			regpush0[0] <= PUSH[0];
			if (regpush1[1:0] == 2'b01 && (!((is_ball_up == 1) && (bally == BAR1_Y) && ((ballx >= bar1) && (ballx <= bar1 + (LENGTH_OF_BAR - 1))))))	begin // 多分，ボールがやってきてバーにぶつかった時には動かないようにする
				if (bar1 == LEFT_MOST) // 左端ならば
					bar1 <= bar1; // そのまま
				else
					bar1 <= bar1 - 3'b1; // 端じゃなければ左に移動
			end
			else if (regpush0[1:0] == 2'b01 && (!((is_ball_up == 1) && (bally == BAR1_Y) && ((ballx >= bar1) && (ballx <= bar1 + (LENGTH_OF_BAR - 1)))))) 	begin // 多分，ボールがやってきてバーにぶつかった時には動かないようにする
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
	always @ (posedge CLK or negedge RSTn) 	begin	
		if (RSTn == 1'b0) 		begin
			bar2 <= RIGHT_MOST - LENGTH_OF_BAR + 1;
			regpush3 [1:0] <= 2'b0;
			regpush2 [1:0] <= 2'b0;
		end
		else if (carryout) 		begin
			regpush3[1] <= regpush3[0];
			regpush3[0] <= PUSH[3];
			regpush2[1] <= regpush2[0];
			regpush2[0] <= PUSH[2];
			if (regpush3[1:0] == 2'b01 && (!((is_ball_up == 0) && (bally == BAR2_Y) && ((ballx >= bar2) && (ballx <= bar2 + (LENGTH_OF_BAR - 1)))))) 	begin // 多分，ボールがやってきてバーにぶつかった時には動かないようにする
				if (bar2 == LEFT_MOST) // 左端ならば
					bar2 <= bar2; // そのまま
				else
					bar2 <= bar2 - 3'b1; // 端じゃなければ左に移動
			end
			else if (regpush2[1:0] == 2'b01 && (!((is_ball_up == 0) && (bally == BAR2_Y) && ((ballx >= bar2) && (ballx <= bar2 + (LENGTH_OF_BAR - 1))))))	begin // 多分，ボールがやってきてバーにぶつかった時には動かないようにする
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
	always @ (posedge CLK or negedge RSTn) 	begin	
		// 初期化
		if(RSTn == 1'b0) begin
			counter <= 0;
			bally <= BAR1_Y; // ボールの初期位置は今後変更すべき
			ballx <= bar1 + 3'b1;
			is_ball_up <= 0;

		end else if(is_ball_up == 1 && bally == BAR1_Y && (ballx >= bar1) && (ballx <= bar1 + (LENGTH_OF_BAR - 1))) begin // ボールがやってきてバー1にぶつかった時は
			// is_ball_up(ボールの方向)のみ逆転させる
			ballx <= ballx;
			bally <= bally;
			is_ball_up <= 0;   

		end else if(is_ball_up == 0 && bally == BAR2_Y && (ballx >= bar2) && (ballx <= bar2 + (LENGTH_OF_BAR - 1))) begin // ボールがやってきてバー2にぶつかった時は
			// is_ball_up(ボールの方向)のみ逆転させる	
			ballx <= ballx;
			bally <= bally; 
			is_ball_up <= 1;

		end else if(is_ball_up == 0) 	begin // is_ball_upが0で，バーにぶつかっていない時
        
			if(bally == UP_MOST && carryout_ball == 1'b1) 	begin // 画面の端ならば
		    	// 止まる
				ballx <= ballx;
				bally <= bally;

		   	end else if(carryout_ball == 1'b1)  	begin	// 普通は
				bally <= bally - 3'b1; //　進む
				
			end else begin		
				bally <= bally; // carryout_ballが切りかわらるまで止まり続ける=carryout_ballがボールのスピードを決めている
			end
		end
		  	  
		else if(is_ball_up == 1) 		begin // is_ball_upが1で，バーにぶつかっていない時
		  
		  if(bally == DOWN_MOST && carryout_ball == 1'b1) 	begin // 画面の端ならば
		  	// 止まる
			ballx <= ballx;
			bally <= bally;
	
		  end else if(carryout_ball == 1'b1)  begin	 // 普通は	
				bally <= bally + 3'b1; // 進む
				
        end else 		
				bally <= bally; // carryout_ballが切りかわらるまで止まり続ける=carryout_ballがボールのスピードを決めている
		end
		  
	end

	// 10bit up ledout that counts up at carryout = 1;
    always @ (posedge CLK or negedge RSTn) 	
        case(color)
			// バー1の表示
			// 長さに応じて表示を変える必要がある
			7'b0000000: ledout <= 10'b1001101000 + bar1;
			7'b0000001: ledout <= 10'b1001101000 + bar1 + 2'b01;
			7'b0000010: ledout <= 10'b1001101000 + bar1 + 2'b10;

			// バー2の表示
			7'b0000011: ledout <= 10'b1000010000 + bar2;
			7'b0000100: ledout <= 10'b1000010000 + bar2 + 2'b01;
			7'b0000110: ledout <= 10'b1000010000 + bar2 + 2'b10;

			// ボールの表示
			7'b0111000: ledout <= 10'b0100000000 + (bally << 3) + ballx;
			7'b0111001: ledout <= 10'b0100000000 + (bally << 3) + ballx;
			7'b0111010: ledout <= 10'b0100000000 + (bally << 3) + ballx;
			
			default : ledout <= 0;
			
		endcase
				
    assign LEDout[9:0] = ledout;     
	// 多分これはまだ使っていない  
    BIN14to7SEG4 binto7seg3 (CLK,RSTn,counter,SEG7OUT,SEG7COM);
	 
endmodule