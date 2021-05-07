
`timescale 1ns/10ps
module LBP ( clk, reset, gray_addr, gray_req, gray_ready, gray_data, lbp_addr, lbp_valid, lbp_data, finish);
input   	clk;
input   	reset;
output  reg[13:0] 	gray_addr;
output     reg    	gray_req;
input   	gray_ready;
input   [7:0] 	gray_data;
output  reg[13:0] 	lbp_addr;
output  reg	lbp_valid;
output  reg[7:0] 	lbp_data;
output  reg	finish;
//====================================================================

//FSM
reg[3:0] state,next_state;
parameter IDLE =0;
parameter Input = 1;
parameter Cal = 2;
parameter Output =3;


//Inbuffer
reg[7:0] in_buffer[0:8];
reg[4:0] step;
integer i;


//step
reg [7:0] pointer,row;


reg [8:0] mask[0:7];
wire b0,b1,b2,b3,b4,b5,b6,b7;
wire [7:0] result;




assign b0 = (in_buffer[4]>in_buffer[0])?0:1;
assign b1 = (in_buffer[4]>in_buffer[1])?0:1;
assign b2 = (in_buffer[4]>in_buffer[2])?0:1;
assign b3 = (in_buffer[4]>in_buffer[3])?0:1;
assign b4 = (in_buffer[4]>in_buffer[5])?0:1;
assign b5 = (in_buffer[4]>in_buffer[6])?0:1;
assign b6 = (in_buffer[4]>in_buffer[7])?0:1;
assign b7 = (in_buffer[4]>in_buffer[8])?0:1;

assign result = b0*mask[0] + b1*mask[1] + b2*mask[2]+b3*mask[3]+b4*mask[4] + b5*mask[5] + b6*mask[6] + b7*mask[7];


initial begin
    mask[0] = 1;
    mask[1] = 2;
    mask[2] = 4;
    mask[3] = 8;
    mask[4] = 16;
    mask[5] = 32;
    mask[6] = 64;
    mask[7] = 128;
end










always@(posedge clk or negedge reset)begin
    if(reset)begin
        state<=IDLE;
    end
    else begin
        state<= next_state;
    end
end


always@(*)begin
    case(state)
        IDLE:begin
            if(gray_ready)begin
                next_state = Cal;
            end
            else begin
                next_state = IDLE;
            end
        end

        Cal:begin
            if(lbp_addr==16383 & step == 5)begin
                next_state<=Output;
            end
            else begin
                next_state<=state;
            end
        end
        Output:begin
            next_state = state;
        end
        default: next_state = IDLE;
    endcase
end


always@(posedge clk or negedge reset)begin
    if(reset)begin
        gray_req<=0;
    end
    else begin
        if(gray_ready & state!=Output)begin
            gray_req<=1;
        end
        else begin
            gray_req<=0;
        end
    end
end



always@(posedge clk or negedge reset)begin
    if(reset)begin
        finish<=0;
    end
    else begin
        if(lbp_addr==16383 & step == 5)begin
            finish<=1;
        end
        else begin
            finish<=finish;
        end
    end
end



always@(posedge clk or negedge reset)begin
    if(reset)begin
        pointer<=0;
    end
    else begin
        if(state == Cal)begin
            if(step==5 && pointer!=127)begin
                pointer<=pointer+1;
            end
            else begin
                if(pointer==127 & step==5)begin
                    pointer<=0;
                end
                else begin
                    pointer<=pointer; 
                end
            end
        end
        else begin
            pointer<=0;
        end
    end
end


always@(posedge clk or negedge reset)begin
    if(reset)begin
        row<=0;
    end
    else begin
        if(pointer == 127 & step==5)begin
            row<=row+1;
        end
        else begin
            row<=row;
        end
    end
end









always@(posedge clk or negedge reset)begin
    if(reset)begin
        for(i=0;i<9;i=i+1)
            in_buffer[i]<=0;
        gray_addr<=0;
        lbp_addr<=0;
        lbp_valid<=0;
        step<=0;
    end
    else begin
        if(state == Cal)begin
            if(row == 0 || row ==127 || pointer==0 || pointer == 127)begin
                case(step)
                    0:begin
                        lbp_valid<=1;
                        lbp_addr<=row*128 + pointer;
                        lbp_data<=0;
                        gray_addr<=gray_addr;
                        step<=5;
                    end
                    5:begin
                        lbp_valid <= 0;
                        step<=0;
                        gray_addr<=gray_addr;
                        lbp_addr<=lbp_addr+1;
                    end
                endcase
            end
            else if(pointer==1)begin
                case(step)
                    0:begin
                        lbp_valid<=0;
                        lbp_addr<=lbp_addr;
                        gray_addr<=gray_addr;
                        step<=1;
                    end
                    1:begin
                        in_buffer[0]<=gray_data;
                        gray_addr<=gray_addr+1;
                        lbp_valid<=0;
                        lbp_addr<=lbp_addr;
                        step<=2;
                    end
                    2:begin
                        in_buffer[1]<=gray_data;
                        gray_addr<=gray_addr+1;
                        lbp_valid<=0;
                        lbp_addr<=lbp_addr;
                        step<=3;
                    end
                    3:begin
                        in_buffer[2]<=gray_data;
                        gray_addr<=gray_addr+126;
                        lbp_valid<=0;
                        lbp_addr<=lbp_addr;
                        step<=4;
                    end
                    4:begin
                        in_buffer[3]<=gray_data;
                        gray_addr<=gray_addr+1;
                        lbp_valid<=0;
                        lbp_addr<=lbp_addr;
                        step<=6;
                    end
                    6:begin
                        in_buffer[4]<=gray_data;
                        gray_addr<=gray_addr+1;
                        lbp_valid<=0;
                        lbp_addr<=lbp_addr;
                        step<=7;
                    end
                    7:begin
                        in_buffer[5]<=gray_data;
                        gray_addr<=gray_addr+126;
                        lbp_valid<=0;
                        lbp_addr<=lbp_addr;
                        step<=8;
                    end
                    8:begin
                        in_buffer[6]<=gray_data;
                        gray_addr<=gray_addr+1;
                        lbp_valid<=0;
                        lbp_addr<=lbp_addr;
                        step<=9;
                    end
                    9:begin
                        in_buffer[7]<=gray_data;
                        gray_addr<=gray_addr+1;
                        lbp_valid<=0;
                        lbp_addr<=lbp_addr;
                        step<=10;
                    end
                    10:begin
                        in_buffer[8]<=gray_data;
                        gray_addr<=gray_addr;
                        step<=11;
                        lbp_valid<=0;
                        lbp_addr<=lbp_addr;
                    end
                    11:begin
                        lbp_valid <= 1;
                        lbp_addr<=lbp_addr;
                        lbp_data<=result;
                        step<=5;
                    end
                    5:begin
                        gray_addr<=(pointer) + (row-1)* 128;
                        lbp_addr<=lbp_addr+1;
                        lbp_valid <= 0;
                        step<=0;
                    end
                endcase
            end
            else begin
                case(step)
                    0:begin
                        in_buffer[0]<=in_buffer[1];
                        in_buffer[1]<=in_buffer[2];
                        in_buffer[3]<=in_buffer[4];
                        in_buffer[4]<=in_buffer[5];
                        in_buffer[6]<=in_buffer[7];
                        in_buffer[7]<=in_buffer[8];
                        gray_addr<=gray_addr+2;
                        step<=1;
                    end
                    1:begin
                        in_buffer[2]<=gray_data;
                        gray_addr<=gray_addr+128;
                        step<=2;
                    end
                    2:begin
                        in_buffer[5]<=gray_data;
                        gray_addr<=gray_addr+128;
                        step<=3;
                    end
                    3:begin
                        in_buffer[8]<=gray_data;
                        gray_addr<=gray_addr;
                        step<=4;
                    end
                    4:begin
                        lbp_valid <= 1;
                        lbp_addr<=lbp_addr;
                        gray_addr<=gray_addr;
                        step<=5;
                        lbp_data<=result;
                    end
                    5:begin
                        lbp_valid <= 0;
                        step<=0;
                        if(pointer==126)begin
                            gray_addr<=pointer + (row-1)* 128+2;
                        end
                        else begin
                            gray_addr<=pointer + (row-1)* 128;
                        end
                        lbp_addr<=lbp_addr+1;
                    end
                endcase
            end
        end
    end
end














//====================================================================
endmodule
