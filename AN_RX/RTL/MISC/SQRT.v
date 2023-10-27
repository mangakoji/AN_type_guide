//SQRT.v
//  SQRT()
// calc square root
//https://www.cadence.com/japan/archive/soconline/vol14/tec/tec_4_2.html
//
//
//
//171021s   :conti.   WIP ?
//170518    :1st. WIP?

module SQRT
#(   parameter  C_W = 8
)(
      input                     CK_i
    , input tri1                XARST_i
    , input tri0                REQ_i
    , input tri0    [2*C_W-1:0] DATs_i
    , output wire   [C_W-1  :0] QQs_o
    , output wire               DONE_o
) ;
    localparam C_SEQ_W = $clog2(C_W+1)+2;
    reg     [C_SEQ_W-1:0] SEQ_CTRs ;
    always @(posedge CK_i or negedge XARST_i)
        if ( ~ XARST_i)
            SEQ_CTRs <= ~('d0) ;
        else 
            if (REQ_i)
                SEQ_CTRs <= 'd0 ;
            else if (~(& SEQ_CTRs))
                SEQ_CTRs <= SEQ_CTRs + 'd1 ;
    wire [1:0]  PHs ;
    wire [C_SEQ_W:0]  IDXs ; //3bit
    assign PHs = SEQ_CTRs[1:0]    ;
    assign IDXs = C_W - SEQ_CTRs[C_SEQ_W-1:2] -1 ;
    wire   done_latch ;
    assign done_latch = (SEQ_CTRs == C_W*4) ;//10_00_00

//    reg     [2*C_W-1:0]   DATs ;
    reg     [C_W:0]     AAs ;
    reg     [C_W:0]     TTs ; //unnessary ?
    reg     [C_W+2:0]   BBs ;
    reg     [C_W+2:0]   CCs ;
    always@(posedge CK_i or negedge XARST_i)
    begin
        if( ~ XARST_i ) 
        begin
//            DATs <= 0;
            BBs <= 'd0 ;
            TTs <= 'd0 ;
            CCs <= 'd0 ;
            AAs <= 'd0 ;
        end else 
        begin
            if( REQ_i ) 
            begin
//                DATs <= DATs_i ;
                BBs <= 'd0 ;
                TTs <= 'd0 ;
                CCs <= 'd0 ;
                AAs <= 'd0 ;
            end else 
            begin
                case( PHs )
                    0:begin
                        if (AAs[IDXs+1])BBs<= 
                                            (CCs <<2) 
                                            | (2'b11&(DATs_i>>(IDXs*2)))
                                        ;
                        else            BBs <= 
                                            (BBs <<2) 
                                            | (2'b11&(DATs_i>>(IDXs*2)))
                                        ;
                    end
                    1:                  TTs <= AAs >> (IDXs+1) ;
                    2:                  CCs <= BBs - {TTs , 2'b01} ;
                    3:                  AAs[IDXs] <= ~ CCs[C_W+2-IDXs] ;
                endcase
            end
        end
    end
    reg [C_W-1 :0] QQs ;
    reg             DONE ;
    always@(posedge CK_i or negedge XARST_i)
    begin
        if( ~ XARST_i)
        begin   QQs <= 'd0;
                DONE <= 1'b0 ;
        end else
        begin 
            if( done_latch )            QQs <= AAs[C_W-1:0] ;
                                        DONE <= done_latch ;
        end
    end
    assign QQs_o = QQs ;
    assign DONE_o = DONE ;
endmodule


`timescale  1ns/1ns
module TB_SQRT #(
     parameter C_C = 10
    ,parameter C_W = 12
)(
) ;
    reg CK_i  ;
    initial 
    begin
        CK_i <= 1'b1 ;
        forever 
        begin
            #(C_C/2) ;
                                        CK_i <= ~ CK_i ;
        end
    end

    reg     XARST_i   ;
    initial 
    begin
        XARST_i <= 1 ;
        #(2) ;
                                        XARST_i <= 0 ;
        #(2) ;
                                        XARST_i <= 1 ;
    end

    reg                 REQ_i   ;
    reg     [C_W*2-1:0] DATs_i  ;
    wire    [C_W-1  :0] QQs_o   ;
    wire                DONE_o  ;
    SQRT 
        #(   .C_W                       ( C_W         )
        )SQRT
        (
              .CK_i                     ( CK_i      )
            , .XARST_i                  ( XARST_i   )
            , .REQ_i                    ( REQ_i     )
            , .DATs_i                   ( DATs_i    )
            , .QQs_o                    ( QQs_o     )
            , .DONE_o                   ( DONE_o    )
        ) 
    ;
    integer DATs_AD ;
    integer xx ;
    integer yy ;
    initial begin
        REQ_i <= 1'b0 ;
        DATs_i <= 0;
        DATs_AD <= 32 ;
        repeat(100)
            @ (posedge CK_i) ;
        for(yy=0; yy<'h2020; yy=yy+1)
         begin
            for(xx=0; xx<65; xx=xx+1) 
            begin
                if(xx==0) DATs_AD <= yy * yy ;
                REQ_i <= (xx==0) ;
                DATs_i <= DATs_AD>>2 ;
                @ (posedge CK_i) ;
            end
        end
        repeat (100) 
            @( posedge CK_i) ;
        $stop ;
    end
endmodule //TB_AAA()
