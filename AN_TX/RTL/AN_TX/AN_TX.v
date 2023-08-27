// AN_TX.v
//  AN_TX()
//N8Ar :1st
`ifndef AN_TX
    `ifndef FPGA_COMPILE
        `include "../MISC/SIN_S11_S11.v"
    `endif
    `include "../MISC/define.vh"
    `default_nettype none
module AN_TX
#(   parameter C_CK_Fs  = 135_000_000
    ,parameter C_TONE_Fs = 440
    ,parameter C_KEY_SHORT_CKN_SELs = 3 //step1
    ,parameter C_SIM_KEY_SHORT_CKNs = 0//10_000
)(   `in`tri1           CK_i
    ,`in`tri1           XARST_i
    ,`out`w             DS_R_o
    ,`out`w             DS_L_o
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
    `r DIV_EE ;
    `w[C_CK_Ws:0] DIVs_a = (DIV_CTRs + C_NUMERATORs ) ; 
    `w DIV_cmp = DIVs_a >= {1'b0,C_DENOMINATORs} ;
    `r[11:0] TONE_CTRs ;
    `ack`xar
    `b  DIV_CTRs <= 0 ;
        DIV_EE <= 0;
        TONE_CTRs <=0 ;
    `eelse
    `b  if( DIV_cmp )                   DIV_CTRs <= DIVs_a - C_DENOMINATORs  ;
        else                            DIV_CTRs <= DIVs_a ;
                                        DIV_EE <= DIV_cmp ;
        if( DIV_EE )
        `b                              `inc( TONE_CTRs ) ;
        `e
    `e
    `w`s[11:0]SINs ;
    SIN_S11_S11
        SIN_S11_S11
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
        // short point[100us] // class
     `lp C_KEY_SHORT_CKNss = {
         12'd33_3           // master
        ,12'd50_0           // step 3
        ,12'd66_7           // step 1
        ,12'd100_0          // class 1
        ,12'd133_3          // class 2
        ,12'd240_0          // class 3
        }
    ;
    `r[12:0] DSs ;
    `ack`xar    DSs <= 13'b1_0111_1111_1111 ;
    else                DSs <= {1'b0,DSs[11:0]}+{1'b0,~SINs[11],SINs[10:0]};
    
//    `lp C_KEY_SHORT_CKN_SELs = 3 ;//step 1 
    `func [31:0] f_C_KEY_SHORT_CKNs ;
        `in ii ;
    `b
        if( C_SIM_KEY_SHORT_CKNs )
            f_C_KEY_SHORT_CKNs = C_SIM_KEY_SHORT_CKNs ;
        else
            f_C_KEY_SHORT_CKNs=
                                C_CK_Fs 
                                * `slice(
                                    C_KEY_SHORT_CKNss
                                    ,C_KEY_SHORT_CKN_SELs
                                    ,12
                                ) / 1000_0 
            ;
    `eefunc
    `lp C_KEY_SHORT_CKNs = f_C_KEY_SHORT_CKNs( 0 ) ;
    `lp C_KS_W = $clog2( C_KEY_SHORT_CKNs * C_CK_Fs / 1000_0) ;
    `r[C_KS_W-1:0] KS_CTRs ;
    `w KS_CTR_cy = (KS_CTRs == 0) ;
    localparam C_CODEs = 8'b000_111_0_1; //N
    reg[ 2:0]PTRNs ;
    `ack`xar
    `b  KS_CTRs <= C_KEY_SHORT_CKNs-1 ;
        PTRNs <= 0 ;
    `eelse
    `b
        if(KS_CTR_cy )
        `b                              KS_CTRs <= C_KEY_SHORT_CKNs-1 ;
                                        `inc( PTRNs ) ;
        `eelse                          `dec(KS_CTRs) ;
    `e
    `r LXR_LE ;
    `r SOUND_LXR ;
    `r DS_L ;
    `r DS_R ;
    `ack`xar
    `b  SOUND_LXR <= 1'b0;
        LXR_LE<=1'b0;
    `eelse
    `b  if(KS_CTR_cy)                   LXR_LE <= 1'b1 ;
        if(LXR_LE)
            if(&TONE_CTRs[10:0])
            `b                          LXR_LE <= 1'b0 ;
                                        SOUND_LXR <= C_CODEs[PTRNs] ;
            `e
                                        DS_R<=(~SOUND_LXR)? ~DS_R: DSs[12] ;
                                        DS_L<=( SOUND_LXR)? ~DS_L: DSs[12] ;
    `e
    `a DS_R_o = DS_R ;
    `a DS_L_o = DS_L ;
`emodule
    `define AN_TX
`endif


`ifndef FPGA_COMPILE
    `ifndef TB_AN_TX
        `timescale 1ns/1ns
        `include "../MISC/define.vh"
        `default_nettype none
module TB_AN_TX
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

    `w             DS_R_o ;
    `w             DS_L_o ;
    `lp C_CK_Fs = 135_000_000;
    AN_TX
        #(   .C_CK_Fs                   ( C_CK_Fs           )
            ,.C_TONE_Fs                 ( C_CK_Fs*3/4/4096  )
            ,.C_SIM_KEY_SHORT_CKNs      ( 4096*3            )
        )AN_TX
        (    .CK_i                      ( CK_i              )
            ,.XARST_i                   ( XARST_i           )
            ,.DS_R_o                    ( DS_R_o            )
            ,.DS_L_o                    ( DS_L_o            )
        ) 
    ;

    `lp C_X_CYCLEs = 100 ;
    `lp C_Y_CYCLEs = 100 ;
    `lp C_Z_CYCLEs = 100 ;
    `int xx,yy,zz ;
    `init
    `b  
        repeat(100)@(`pe CK_i);
        repeat( 2 )
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
        `define TB_AN_TX
    `endif
`endif

