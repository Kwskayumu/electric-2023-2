// ball2を消した，top2を消した．跳ね返ったらtopを逆転させるようにした
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
reg [1:0] top;
reg [21:0] prescaler;
reg [30:0] prescaler_ball;
reg [6:0] color;
reg [1:0] regrotA;   //rotary encoder phase A rising
reg [1:0] regpush0;
reg [1:0] regpush1;
reg [1:0] regpush2;
reg [1:0] regpush3;

reg [9:0] counter;

wire carryout;

    always @ (posedge CLK or negedge RSTn) 	begin	
        if(RSTn == 1'b0) 	begin	
            prescaler <= 22'b0;
		  end
        else if(prescaler == 22'd2000) 
            prescaler <= 22'b0;
        else
            prescaler <= prescaler + 22'b1;
    end
    assign    carryout = (prescaler == 22'd2000) ? 1'b1 : 1'b0;

	 always @ (posedge CLK or negedge RSTn) 	begin	
        if(RSTn == 1'b0) 		begin
            prescaler_ball <= 31'b0;
		  end
        else if(prescaler_ball == 31'd4000000)
            prescaler_ball <= 31'b0;
        else
            prescaler_ball <= prescaler_ball + 31'b1;
    end
    assign    carryout_ball = (prescaler_ball == 31'd4000000) ? 1'b1 : 1'b0;
	 
    always @ (posedge CLK) 	begin	
		  if (carryout == 1'b1) 		begin
			  if (color == 7'b1111111)
			     color <= 7'b0;
			  else
			     color <= color + 7'b1;
		  end
    end

    //change bar1 position by switch
	always @ (posedge CLK or negedge RSTn) 	begin	
		if (RSTn == 1'b0) 		begin
			bar1 <= 3'b000;
			regpush1 [1:0] <= 2'b0;
			regpush0 [1:0] <= 2'b0;
		end
		else if (carryout) 	begin	
			regpush1[1] <= regpush1[0];
			regpush1[0] <= PUSH[1];
			regpush0[1] <= regpush0[0];
			regpush0[0] <= PUSH[0];
			if (regpush1[1:0] == 2'b01 && (!((top == 1) && (bally == 4'b1100) && ((ballx == bar1 || ballx == bar1 +3'b1 || ballx == bar1 +3'b10)))))	begin	 //go left
				if (bar1 == 3'b000) //left edge
					bar1 <= bar1; //stay
				else
					bar1 <= bar1 - 3'b1;
			end
			else if (regpush0[1:0] == 2'b01 && (!((top == 1) && (bally == 4'b1100) && ((ballx == bar1 || ballx == bar1 +3'b1 || ballx == bar1 +3'b10))))) 	begin	 //go right
				if (bar1 == 3'b101) //right edge
					bar1 <= bar1; //stay
				else
					bar1 <= bar1 + 3'b1;
			end
			else
				bar1 <= bar1;
		end
	end

    //change bar2 position by switch
	always @ (posedge CLK or negedge RSTn) 	begin	
		if (RSTn == 1'b0) 		begin
			bar2 <= 3'b101;
			regpush3 [1:0] <= 2'b0;
			regpush2 [1:0] <= 2'b0;
		end
		else if (carryout) 		begin
			regpush3[1] <= regpush3[0];
			regpush3[0] <= PUSH[3];
			regpush2[1] <= regpush2[0];
			regpush2[0] <= PUSH[2];
			if (regpush3[1:0] == 2'b01 && (!((top == 0) && (bally == 4'b0011) && ((ballx == bar2 || ballx == bar2 +3'b1 || ballx == bar2 +3'b10))))) 	begin	 //go left
				if (bar2 == 3'b000) //left edge
					bar2 <= bar2; //stay
				else
					bar2 <= bar2 - 3'b1;
			end
			else if (regpush2[1:0] == 2'b01 && (!((top == 0) && (bally == 4'b0011) && ((ballx == bar2 || ballx == bar2 +3'b1 || ballx == bar2 +3'b10)))))	begin	 //go left
				if (bar2 == 3'b101) //right edge
					bar2 <= bar2; //stay
				else
					bar2 <= bar2 + 3'b1;
			end
			else
				bar2 <= bar2;
		end
	end
	
	//ball move
    // 10bit up counter that counts up at carryout = 1;
	always @ (posedge CLK or negedge RSTn) 	begin	
		if(RSTn == 1'b0) begin
			counter <= 0;
			bally <= 4'b1100;
			ballx <= bar1 + 3'b1;
			top <= 0;

		end else if(top == 1 && bally == 4'b1100 && (ballx == bar1 || ballx == bar1 +3'b1 || ballx == bar1 +3'b10)) begin
			ballx <= ballx;
			bally <= bally;
			top <= 0;   

		end else if(top == 0 && bally == 4'b0011 && (ballx == bar2 || ballx == bar2 +3'b1 || ballx == bar2 +3'b10)) begin		
			ballx <= ballx;
			bally <= bally; 
			top <= 1;

		end else if(top == 0) 	begin	//down
        
		   if(bally == 4'b0000 && carryout_ball == 1'b1) 	begin	
			ballx <= ballx;
			bally <= bally;

		   end else if(carryout_ball == 1'b1)  	begin	
				bally <= bally - 3'b1;
				
         end else 		
				bally <= bally;
		end
		  	  
		else if(top == 1) 		begin //up
		  
		  if(bally == 4'b1111 && carryout_ball == 1'b1) 		begin
			ballx <= ballx;
			bally <= bally;
	
		  end else if(carryout_ball == 1'b1)  begin		
				bally <= bally + 3'b1;
				
        end else 		
				bally <= bally;
		end
		  
	end

	// 10bit up ledout that counts up at carryout = 1;
    always @ (posedge CLK or negedge RSTn) 	
        case(color)
			7'b0000000: ledout <= 10'b1001101000 + bar1;
			7'b0000001: ledout <= 10'b1001101000 + bar1 + 2'b01;
			7'b0000010: ledout <= 10'b1001101000 + bar1 + 2'b10;

			7'b0000011: ledout <= 10'b1000010000 + bar2;
			7'b0000100: ledout <= 10'b1000010000 + bar2 + 2'b01;
			7'b0000110: ledout <= 10'b1000010000 + bar2 + 2'b10;

			7'b0111000: ledout <= 10'b0100000000 + (bally << 3) + ballx;
			7'b0111001: ledout <= 10'b0100000000 + (bally << 3) + ballx;
			7'b0111010: ledout <= 10'b0100000000 + (bally << 3) + ballx;
			
			default : ledout <= 0;
			
		endcase
				
    assign LEDout[9:0] = ledout;       
    BIN14to7SEG4 binto7seg3 (CLK,RSTn,counter,SEG7OUT,SEG7COM);
	 
endmodule