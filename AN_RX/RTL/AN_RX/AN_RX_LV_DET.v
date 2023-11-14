// AN_RX_LV_DET.v
//  AN_RX_LV_DET()
//N8Ar :1st
`ifndef AN_RX_LV_DET
    `ifndef FPGA_COMPILE
        `include "../MISC/SIN_S11_S11.v"
        `include "../MISC/SQRT.v"
    `endif
    `include "../MISC/define.vh"
    `default_nettype none
module AN_RX_LV_DET
#(   parameter C_CK_Fs  = 48_000_000
    ,parameter C_TONE_Fs = 440
)(   `in`tri1           CK_i
    ,`in`tri1           XARST_i
    ,`in`tri0           MIC_i
    ,`out`w             MIC_CK_o
    ,`out`w[11:0]       LVs_o
    ,`out`w             LV_o
    ,`out`w             DONE_o
) ;
    
    `func [63:0] f_GCMs ;
        `in[63:0]As ;
        `in[63:0]Bs ;
    `b
        for(f_GCMs=As;Bs!=0;As=As)
                                        {Bs,f_GCMs}=
                                            {(f_GCMs-(f_GCMs/Bs)*Bs),Bs}
                                        ;
    `eefunc
    `lp C_GCMs = f_GCMs( 4096 * C_TONE_Fs , C_CK_Fs ) ;
    `lp C_NUMERATORs  = C_TONE_Fs * 4096 / C_GCMs ;
    `lp C_DENOMINATORs = C_CK_Fs / C_GCMs ;
    `lp C_CK_Ws = $clog2( C_DENOMINATORs ) ;
    `r[C_CK_Ws-1:0] DIV_CTRs ;
    `r DIV_EE_AD ;
    `w[C_CK_Ws:0] DIVs_a = (DIV_CTRs + C_NUMERATORs ) ; 
    `w DIV_cmp = DIVs_a >= {1'b0,C_DENOMINATORs} ;
    `r[11:0] TONE_CTRs ;
    `ack`xar
    `b  DIV_CTRs <= 0 ;
        DIV_EE_AD <= 0;
        TONE_CTRs <=0 ;
    `eelse
    `b  if( DIV_cmp )                   DIV_CTRs <= DIVs_a - C_DENOMINATORs  ;
        else                            DIV_CTRs <= DIVs_a ;
                                        DIV_EE_AD <= DIV_cmp ;
        if( DIV_EE_AD )                    `inc( TONE_CTRs ) ;
    `e
    // DIV_EE_AD    _-________-________-________-________-___
    // MIC_CK       __---------_________---------_________---
    //MIC_CK_Ds[0]  ___---------_________---------_________--
    //MIC_CK_Ds[1]  ____---------_________---------_________--
    //MIC_CK_Ds[2]  _____---------_________---------_________--
    //(MIC_CK_o)
    //DIV_EE        ___________-_________________-______________
    //DIV_EE_Ds[0]  ____________-_________________-______________
    //TONE_CY_Ds[0]
    //DIV_EE_Ds[1]  _____________-_________________-______________
    //DIV_EE_Ds[2]  ______________-_________________-______________
    `r MIC_CK ;
    `r[2:0]MIC_CK_Ds ;
    `r DIV_EE ;
    `w TONE_cy = (&TONE_CTRs) & DIV_EE ;
    `r[6:0]DIV_EE_Ds ;
    `r[7:0]TONE_CY_Ds ;
    `ack`xar    
    `b  MIC_CK<=1'b0 ;
        DIV_EE <=1'b0 ;
    `eelse
    `b  if( DIV_EE_AD )                 `incn(MIC_CK , 1) ;
                                        DIV_EE <= ~ MIC_CK & DIV_EE_AD ;
                                        
                                        `sfl(MIC_CK_Ds,MIC_CK) ;
                                        `sfl(DIV_EE_Ds , DIV_EE) ;
                                        `sfl(TONE_CY_Ds,TONE_cy);
    `e
    `a MIC_CK_o = MIC_CK_Ds[2] ;
    `w`s[11:0]SINs ;
    SIN_S11_S11
        SIN_ROM
        (
             .CK_i                      ( CK_i              )
            ,.XARST_i                   ( XARST_i           )
//            ,.CK_EE_i                   ()
//            ,.B_IN_DAT_DLYs_i           ()
            ,.DATs_i                    ( TONE_CTRs[11:0]   )//2's -h800 +7FFF
            ,.SINs_o                    ( SINs              )//2's -h7ff 0 +h7FF
//            ,.DONE_o                    ()
//            ,.B_OUT_DAT_DLYs_o          ()
        ) 
    ;
    //   sin      cos
    //  01 00    10 01
    //  10 11    11 00
    //
    `r`s[11:0]COS_TONE_ctr_s;
    `al@( TONE_CTRs )
        case(TONE_CTRs[11:10])
            2'b00:                  COS_TONE_ctr_s={2'b01,TONE_CTRs[9:0]};
            2'b01:                  COS_TONE_ctr_s={2'b10,TONE_CTRs[9:0]};
            2'b10:                  COS_TONE_ctr_s={2'b11,TONE_CTRs[9:0]};
            2'b11:                  COS_TONE_ctr_s={2'b00,TONE_CTRs[9:0]};
        `ecase
    `w`s[11:0]COSs ;
    SIN_S11_S11
        COS_ROM
        (
             .CK_i                      ( CK_i              )
            ,.XARST_i                   ( XARST_i           )
//            ,.CK_EE_i                   ()
//            ,.B_IN_DAT_DLYs_i           ()
            ,.DATs_i                    ( COS_TONE_ctr_s[11:0])
            ,.SINs_o                    ( COSs              )//2's -h7ff 0 +h7FF
//            ,.DONE_o                    ()
//            ,.B_OUT_DAT_DLYs_o          ()
        ) 
    ;
    `r[1:0]MIC_Ds ;
    `r`s[23:0]SIN_SIGMAs;
    `r`s[23:0]COS_SIGMAs;
    `r`s[23:0]SIN_SIGMAs_D;
    `r`s[23:0]COS_SIGMAs_D;
    `r`s[12:0]CIC_SINs;   // 440Hz sampled CIC LPF out
    `r`s[12:0]CIC_COSs;   
    `ack`xar
    `b  SIN_SIGMAs<=0;
        COS_SIGMAs<=0;
        SIN_SIGMAs_D<=0;
        COS_SIGMAs_D<=0;
        CIC_SINs <= 0 ;
        CIC_COSs <= 0 ;
    `eelse
    `b                                  
                                        `sfl(MIC_Ds, MIC_i) ;
        if(DIV_EE_Ds[2] )//4096*440Hz
        `b
            if( MIC_Ds[1] )
            `b                          SIN_SIGMAs<=
                                            SIN_SIGMAs 
                                            + {{12{SINs[11]}},SINs} 
                                        ;
                                        COS_SIGMAs<=
                                            COS_SIGMAs 
                                            + {{12{COSs[11]}},COSs}
                                        ;
            `eelse
            `b                          
                                        SIN_SIGMAs<=
                                            SIN_SIGMAs 
                                            - {{12{SINs[11]}},SINs}
                                        ;
                                        COS_SIGMAs<=
                                            COS_SIGMAs 
                                            - {{12{COSs[11]}},COSs}
                                        ;
            `e
            if(TONE_CY_Ds[2]) //440Hz 4096sample
            `b
                                        SIN_SIGMAs_D<= SIN_SIGMAs; 
                                        COS_SIGMAs_D<= COS_SIGMAs; 
                                        CIC_SINs<=(SIN_SIGMAs-SIN_SIGMAs_D)>>>10; 
                                        CIC_COSs<=(COS_SIGMAs-COS_SIGMAs_D)>>>10; 
            `e
        `e
    `e
    `w`s[12:0] mul_A_s = (TONE_CY_Ds[3])? CIC_SINs : CIC_COSs ;
    `r`s[12:0] MUL_AYs ;
    `ack`xar MUL_AYs = 0 ;
    else
    `b  if(mul_A_s[12])                 MUL_AYs = -mul_A_s ;
        else                            MUL_AYs = mul_A_s ;
        if(MUL_AYs>=13'h1000)            MUL_AYs = 13'hFFF ;
    `e
    `r[23:0]CIC_MULs;
    `ack`xar CIC_MULs <=0 ;
    else                                CIC_MULs <= 
                                            {12'd0,MUL_AYs} 
                                            * {12'd0,MUL_AYs} 
                                        ;

    `r[23:0]CIC_SQU_ADDs ;
    `ack`xar
    `b  CIC_SQU_ADDs <= 0;
    `eelse
    `b  if( TONE_CY_Ds[4] )             CIC_SQU_ADDs <= CIC_MULs ;
        if( TONE_CY_Ds[5] )             `incn(CIC_SQU_ADDs , CIC_MULs) ;
        
    `e
    `w[11:0] SQRT_QQs ;
    SQRT
        #(
             .C_W                       ( 12                    )
        )SQRT
        (    .CK_i                      ( CK_i                  )
            ,.XARST_i                   ( XARST_i               )
            ,.REQ_i                     ( TONE_CY_Ds   [7]     )
            ,.DATs_i                    ( CIC_SQU_ADDs          )
            ,.QQs_o                     ( SQRT_QQs              )
            ,.DONE_o                    ( DONE_o                )
        )
    ;
    `a LVs_o = SQRT_QQs ;

    `r[11:0] LV_LOGs ;
    `ack`xar LV_LOGs<=0 ;
    else casex(SQRT_QQs)
            12'b1xxx_xxxx_xxxx:         LV_LOGs<= {4'hF,SQRT_QQs[10:3]};
            12'b01xx_xxxx_xxxx:         LV_LOGs<= {4'hE,SQRT_QQs[ 9:2]};
            12'b001x_xxxx_xxxx:         LV_LOGs<= {4'hD,SQRT_QQs[ 8:1]};
            12'b0001_xxxx_xxxx:         LV_LOGs<= {4'hC,SQRT_QQs[ 7:0]};
            12'b0000_1xxx_xxxx:         LV_LOGs<= {4'hB,SQRT_QQs[ 6:0],1'b1};
            12'b0000_01xx_xxxx:         LV_LOGs<= {4'hA,SQRT_QQs[ 5:0],2'h2};
            12'b0000_001x_xxxx:         LV_LOGs<= {4'h9,SQRT_QQs[ 4:0],3'h4};
            12'b0000_0001_xxxx:         LV_LOGs<= {4'h8,SQRT_QQs[ 3:0],4'h8};
            12'b0000_0x00_1xxx:         LV_LOGs<= {4'h7,SQRT_QQs[ 2:0],5'h10};
            12'b0000_0000_01xx:         LV_LOGs<= {4'h6,SQRT_QQs[ 1:0],6'h20};
            12'b0000_0000_001x:         LV_LOGs<= {4'h5,SQRT_QQs[ 0]  ,7'h40};
            12'b0000_0000_00x1:         LV_LOGs<= {4'h4,8'h80};
            12'b0000_0000_0000:         LV_LOGs<= {4'h3,8'h80};
        endcase
    `r[12:0]IIRs ;
    `ack`xar IIRs <= 13'h0_800 ;
    else IIRs<={1'b0,IIRs[11:0]}+{1'b0,LV_LOGs};
    `a LV_o = IIRs[12] ;
`emodule
    `define AN_RX_LV_DET
`endif


`ifndef FPGA_COMPILE
    `ifndef TB_AN_RX_LV_DET
        `timescale 1ns/1ns
        `include "../MISC/define.vh"
        `default_nettype none
module TB_AN_RX_LV_DET
;
    `r CK_i,XARST_i ;
    `init
    `b
        CK_i <= 1 ;
        #0.1 ;
        forever
        `b
            #5 CK_i <= ~CK_i ;
        `e
    `e
    `init
    `b
        XARST_i <= 1'b0 ;
        #10.5 XARST_i <= 1'b1 ;
    `e
    `w`s[11:0] SINs ;
    `w`s[11:0] COSs ;
    `int xx,yy,zz ;
    `init force SINs = AN_RX_LV_DET.SINs ;
    `init force COSs = AN_RX_LV_DET.COSs ;
//    `w`s[12:0] SCOSs_sft =  {SINs[11],SINs[10:0],1'b0};
//    `w`s[12:0] SCOSs_sft =  {{3{SINs[11]}},SINs[10:1]};

     `r`s[12:0] SCOSs_sft ;
    always@(*)
    `b  case( zz )
            0:     SCOSs_sft      =  {SINs[11],SINs} ;
            1:     SCOSs_sft      =  SINs[11] ? 13'h1800 : 13'h07FF ;
            2:     SCOSs_sft      =  {SINs,1'b0} ;
            3:     SCOSs_sft      =  SINs[11] ? 13'h1000 : 13'h0FFF ;
        `ecase
    `e
//    `w`s[12:0] SCOSs_sft = {COSs[11],COSs[10:0],1'b0};
//    `w`s[12:0] SCOSs_sft = {SINs[11],SINs[11:0]}+{COSs[11],COSs[11:0]};

    `r[12:0] IIRs ;
    `w      MIC_CK_o ;
    `r      MIC_CK_D ;
    `ack`xar
    `b  IIRs <= 13'h0_800;
        MIC_CK_D <= 1'b0;
    `eelse
    `b                                  MIC_CK_D <= MIC_CK_o;
        if(~ MIC_CK_D & MIC_CK_o)       IIRs<={1'b0,IIRs[11:0]}+{1'b0,~SCOSs_sft[12],SCOSs_sft[11:1]};
    `e
    `w MIC_i    = IIRs[12] ;
    parameter C_CK_Fs   = 48_000_000     ;
    parameter C_TONE_Fs = 440           ;
    `w[11:0]       LVs_o    ;
    `w             LV_o     ;
    `w             DONE_o   ;
    AN_RX_LV_DET
        #(   .C_CK_Fs                   ( C_CK_Fs       )
            ,.C_TONE_Fs                 ( C_TONE_Fs     )
        )AN_RX_LV_DET
        (    .CK_i                      ( CK_i          )
            ,.XARST_i                   ( XARST_i       )
            ,.MIC_i                     ( MIC_i         )
            ,.MIC_CK_o                  ( MIC_CK_o      )
            ,.LVs_o                     ( LVs_o         )
            ,.LV_o                      ( LV_o          )
            ,.DONE_o                    ( DONE_o        )
        ) 
    ;

    `lp C_X_CYCLEs = 1000;
    `lp C_Y_CYCLEs = 500;
    `lp C_Z_CYCLEs = 4 ;
    `init
    `b  xx=0;yy=0;zz=0;
        repeat(100)@(`pe CK_i);
        repeat( 2 )@(`pe CK_i);
        `fori(zz,C_Z_CYCLEs)
        `b `fori(yy,C_Y_CYCLEs)
          `b `fori(xx,C_X_CYCLEs)
            `b                          
                @(posedge CK_i) ;
            `e
          `e
        `e
        repeat(500)@(`pe CK_i);
        $stop ;
    `e
`emodule
        `define TB_AN_RX_LV_DET
    `endif
`endif

