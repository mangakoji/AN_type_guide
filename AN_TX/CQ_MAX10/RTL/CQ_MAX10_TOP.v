// CQ_MAX10_TOP.v
//      CQ_MAX10_TOP()
//
//
//N8RuK9: 1st for AN_TX

`ifndef CQ_MAX10_TOP
`include "../../RTL/MISC/define.vh"
`default_nettype none
module CQ_MAX10_TOP
#(
    parameter C_F_MCK = 48_000_000
    // 910*525*30/1.001
)(
      input     CK48M_i     //CLK0_p    27
    , input     XPSW_i      //123
    , output    XLED_R_o    //120
    , output    XLED_G_o    //122
    , output    XLED_B_o    //121

    // CN1
    , inout     P62
    , inout     P61
    , inout     P60
    , inout     P59
    , inout     P58
    , inout     P57
    , inout     P56
    , inout     P55
    , inout     P52
    , inout     P50
    , inout     P48
    , inout     P47
    , inout     P46
    , inout     P45
    , inout     P44
    , inout     P43
    , inout     P41
    , inout     P39
    , inout     P38
    // CN2
    , inout     P124
    , inout     P127
    , inout     P130
    , inout     P131
    , inout     P132
    , inout     P134
    , inout     P135
    , inout     P140
    , inout     P141
//    , inout     P3 //analog AD pin
    , inout     P6
    , inout     P7
    , inout     P8
    , inout     P10
    , inout     P11
    , inout     P12
    , inout     P13
    , inout     P14
    , inout     P17

    // CN5
    , input     P28     //CLK1_n
    , inout     P29     //CLK1_p
    , inout     P30     
    , inout     P32
    , inout     P33
    , inout     P54

    // CN6
    , inout     P21
    , inout     P22
    , inout     P24
    , inout     P25
    , input     P26     //CLK0_n

    //SDRAM
    , output[1:0]   SDRAM_BADRs_o
    , output[12:0]  SDRAM_ADRs_o
    , output        SDRAM_CLK_o
    , output        SDRAM_QDML_o
    , output        SDRAM_QDMH_o
    , output        SDRAM_CKE_o
    , output        SDRAM_XCS_o
    , output        SDRAM_XWE_o
    , output        SDRAM_XRAS_o
    , output        SDRAM_XCAS_o
    , inout [15:0]  SDRAM_DATs_io
) ;
    function integer log2;
        input integer value ;
    begin
        value = value-1;
        for (log2=0; value>0; log2=log2+1)
            value = value>>1;
    end endfunction


    // start
    `lp C_F_CKX = 48_000_000 ;//xtal clock speed 
//    `lp C_F_CKM = 48_000_000 * 5 * 9 / 16  ;// 135MHz
    `lp C_F_CKM  = 135_000_000 ;
    wire            pll_locked      ;
    reg [1:0]       PLL_LOCKED_Ds   ;
    wire            XARST           ;
    wire            CK              ;
    PLL u_PLL(
              .areset       ( 1'b0          )
            , .inclk0       ( CK48M_i       )
            , .c0           ( CK            )
            , .locked       ( pll_locked    )
    ) ;
    always@(posedge CK or negedge pll_locked)
        if( ~ pll_locked )
            PLL_LOCKED_Ds <= 0 ;
        else
            PLL_LOCKED_Ds <= {PLL_LOCKED_Ds , 1'b1 } ;
    assign XARST = PLL_LOCKED_Ds[1] ;
    wire CK_i = CK ;
    wire XARST_i = XARST ;

    `w[1:0]  PSWs_i     ;
    `w LED_R_o ;
    `w LED_G_o ;
    `w LED_B_o ;


    `w DS_R_o ;
    `w DS_L_o ;
    `w SOUND_LXR_o ;
    AN_TX
        #(   .C_CK_Fs                   ( C_F_CKM           )
            ,.C_TONE_Fs                 ( 440               )
//            ,.C_SIM_KEY_SHORT_CKNs      ( 0 )
        )AN_TX
        (    .CK_i                      ( CK_i              )
            ,.XARST_i                   ( XARST_i           )
            ,.DS_R_o                    ( DS_R_o            )
            ,.DS_L_o                    ( DS_L_o            )
            ,.SOUND_LXR_o               ( SOUND_LXR_o       )
        ) 
    ;
    `a LED_R_o = SOUND_LXR_o ;

    // JTAG Test I/Os
    wire [63:0] BJ_DBGOs ;
    wire [63:0] BJ_DBGs ;
    JTAG_DBGER 
        JTAG_DBGER 
        (
              .probe    ( BJ_DBGOs   )
            , .source   ( BJ_DBGs    )
        ) 
    ;
    `w[3:0] BJO_SELs_i  = BJ_DBGs[43:40] ;
    `include "./MISC/TIMESTAMP.v"         
    `a BJ_DBGOs[63:32] = C_TIMESTAMP ;
    `a  BJ_DBGOs[2] =SOUND_LXR_o ;
    `a BJ_DBGOs[1] =DS_R_o ;
    `a BJ_DBGOs[0] =DS_L_o ; 
    `a LED_G_o = BJ_DBGs[ 39 ] ;
    `a LED_B_o = BJ_DBGs[ 39 ] ;


    // pin port list
//    `a CK48M_i            ;//27  CLK0_p
//    `a XPSW_i             ;//123
    `a PSWs_i[0] = XPSW_i   ;//123
    `a XLED_R_o = ~LED_R_o  ;//120
    `a XLED_G_o = ~LED_G_o  ;//122
    `a XLED_B_o = ~LED_B_o  ;//121
    // CN1
    `a P62 = 1'bz ;
    `a P61 = 1'bz ;
    `a P60 = 1'bz ;
    `a P59 = 1'bz ;
    `a P58 = 1'bz ;
    `a P57 = 1'bz ;
    `a P56 = 1'bz ;
    `a P55 = 1'bz ;
    `a P52 = 1'bz ;
    `a P50 = 1'bz ;
    `a P48 = 1'bz ;
    `a P47 = 1'bz ;
    `a P46 = 1'bz ;
    `a P45 = 1'bz ;
    `a P44 = 1'bz ;
    `a P43 = SOUND_LXR_o ;
    `a P41 = DS_R_o ;
    `a P39 = DS_L_o ; 
    `a P38 = DS_L_o ;
    // CN2  
    `a P124 = 1'bz   ;
    `a P127 = 1'bz  ; // 9
    `a P130 = 1'bz  ; // 8
    `a P131 = 1'bz  ; // 7
    `a P132 = 1'bz  ;
    `a P134 = 1'bz  ;
    `a P135 = 1'bz  ; // 4
    `a P140 = 1'bz  ; // 3
    `a P141 = 1'bz  ;
//      P3 //fix analog AD0 pin
    `a P6  = 1'bz ; //AD1
    `a P7  = 1'bz ; //AD2
    `a P8  = 1'bz ; //AD3
    `a P10 = 1'bz ; //AD4
    `a P11 = 1'bz ; //AD5
    `a P12 = 1'bz ; //AD6   //NG@#1
    `a P13 = 1'bz ; //AD7   //NG@#1
    `a P14 = 1'bz ; //AD8
    `a P17 = 1'bz ;         //NG@#1
    // CN5
//    `a P28 = 1'bz ; //CLK1_n 
    `a P29 = 1'bz ; //CLK1_p 
    `a P30 = 1'bz ;
    `a P32 = 1'bz ;
    `a P33 = 1'bz ;
    `a P54 = 1'bz ;
    // CN6
    `a P21 = 1'bz ;
    `a P22 = 1'bz ;
    `a P24 = 1'bz ;
    `a P25 = 1'bz ;
//    `a P26 ; //CLK0_n
    //SDRAM
    `a SDRAM_BADRs_o = 2'bzz ;
    `a SDRAM_ADRs_o  = {13{1'bz}} ;
    `a SDRAM_CLK_o   = 1'bz ;
    `a SDRAM_QDML_o  = 1'bz ;
    `a SDRAM_QDMH_o  = 1'bz ;
    `a SDRAM_CKE_o   = 1'bz ;
    `a SDRAM_XCS_o   = 1'bz ;
    `a SDRAM_XWE_o   = 1'bz ;
    `a SDRAM_XRAS_o  = 1'bz ;
    `a SDRAM_XCAS_o  = 1'bz ;
    `a SDRAM_DATs_io = {16{1'bz}} ;
endmodule //CQ_MAX10_TOP
    `define CQ_MAX10_TOP
`endif
