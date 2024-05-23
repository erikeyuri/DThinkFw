#Include 'Protheus.ch'


Static aRet__Func := {}
Static aRet__Class:= {}
Static cErroA	:= ""
Static __nBuffer := 40

/*
User Function CALLCHGXNU() //Afterlogin()

    SetKey(K_ALT_S, {|| U_TIDev() })

Return Paramixb[5]
*/

/*{Protheus.doc} TIDev
Ferramentas úteis ao desenvolvimento.
@type function
@version 
@author Sandro
@since 14/02/2018
@return 
*/
User Function TIDev()
    Local cUsrLog := ""
    Local cPswLog := ""

    If EysLogin(cUsrLog, cPswLog)
            
        ExecTiDev()

    EndIf

Return


Static Function ExecTiDev()


    If Type("OMAINWND") != "O"

        Private oShortList
        Private oMainWnd
        Private oFont
        Private lLeft     := .F.
        Private cVersao   := GetVersao()
        Private dDataBase := MsDate()
        Private cUsuario  := "TOTVS"

        DEFINE FONT oFont NAME "MS Sans Serif" SIZE 0, -9

        DEFINE WINDOW oMainWnd FROM 0,0 TO 0,0 TITLE "TIDev"
        oMainWnd:oFont := oFont
        oMainWnd:SetColor(CLR_BLACK,CLR_WHITE)
        oMainWnd:Cargo := oShortList
        oMainWnd:nClrText := 0
        //oMainWnd:lEscClose := .T.
        oMainWnd:ReadClientCoors()


        set epoch to 1980
        set century on

        ACTIVATE WINDOW oMainWnd MAXIMIZED ON INIT (MainDevApp(.T.) , oMainWnd:End())
    Else
        MainDevApp()
    EndIf

Return

Static Function MainDevApp(lInit)
    Local oDlg
    Local oRect
    Local oSize
    Local oFol
    Local oFolQry
    Local oFolDic
    
    Local aEmpExQr  := {}
    Local aFolder   := {'Query','Tabelas', 'Inspeção de Funções/Comandos', 'Linha de Comando','Html', 'File Explorer',"Monitor","Serviço","Error",'Conversor Base64', "Grupo" }
    Local aSFolder  := {"Query #1", "Query #2", "Query #3", "Query #4", "Query #5"}
    Local aSFolder2 := {"Tabela #1", "Tabela #2", "Tabela #3", "Tabela #4", "Tabela #5"}
    
    Local nSF := 0
    Local oKf6
    Local lOk:= .F.
    Local lSetAnt := Set(11)


    Static oFolBMP := LoadBitmap( GetResources(), "F5_AMAR")
    Static oFilBMP := LoadBitmap( GetResources(), "LBNO")
    Static cMaskArq := "*.*"

    Private lSqlExec  := .F.
    Private lReadOnly := .T.
    Private lDeleON   := .T.
    Private cUsrFs   := Space(25)  //"Administrador"
    Private cPswFS   := Space(25)
    Private aQryHst  := {{},{},{},{},{}}
    Private aCmdHst  := {}
    Private aB64Hst  := {}
    Private aDicBrw  :=Array(5)
    Private aSXBrw   := Array(5)
    Private aSXLBrw  := Array(5)
    Private aAliasDic:= Array(5)
    Private aQryBrw  :=Array(5)
    Private oTimer

    Private oInfBrw

    Private lDic
    Private lRPO := lClasse := lADVPL := .T.
    Private lTrataErro := .T.

    LimpaTmp()
    LoadJson()

    Set(11,"on")

    SetFolder(1)

    oSize := FwDefSize():New(.F.)
    oSize:AddObject( "PANEL" , 100, 100, .T., .T. )

    If lInit
        oSize:aWorkArea := {0,25,oMainWnd:nRight-15,oMainWnd:nBottom-100}
        cEmpAnt := ''
        cFilAnt := ''
        oRect := TRect():New(7,-1,oMainWnd:nBottom-17,oMainWnd:nRight-7)
    Else
        oRect := TRect():New(0,0,oMainWnd:nBottom-40 /*17*/,oMainWnd:nRight-7)
        oSize:aWorkArea := {0,25,oMainWnd:nRight-15,oMainWnd:nBottom-37}
    EndIF
    oSize:lProp := .T.
    oSize:Process()

    oKf6 := SetKey(VK_F6 ,{|| lSqlExec := ! lSqlExec}) // SqlExec

    DEFINE MSDIALOG oDlg FROM 0,0 TO 0,0 TITLE  "Ferramenta de desenvolvimento"
    oDlg:lEscClose := .F.
    oDlg:SetCoors(oRect)
    oFol := TFolder():New(, , aFolder, aFolder, oDlg, , , , .T., .F.)
    oFol:bSetOption:= {|n| SetFolder(n), .T.}
    oFol:Align := CONTROL_ALIGN_ALLCLIENT


    oFolQry := TFolder():New(, , aSFolder, aSFolder, oFol:aDialogs[1], , , , .T., .F.)
    oFolQry:Align := CONTROL_ALIGN_ALLCLIENT
    //--Folder Query
    For nSF := 1 to 5 //len(aSFolder)
        FolderQry(oFolQry:aDialogs[nSF], oSize, nSF)
    Next

    oFolDic := TFolder():New(, , aSFolder2, aSFolder2, oFol:aDialogs[2], , , , .T., .F.)
    oFolDic:Align := CONTROL_ALIGN_ALLCLIENT
    //--Folder Dicionario
    For nSF := 1 to 5 //len(aSFolder)
        FolderDic(oFolDic:aDialogs[nSF], oSize, nSF)
    Next

    FolderInsp(oFol:aDialogs[3], oSize)        //--Folder Inspeção de Funções/Comandos
    FolderCmd(oFol:aDialogs[4], oSize)         //--Folder Comandos
    FolderHtm(oFol:aDialogs[5], oSize)	       //--Folder Html
    FolderExp(oFol:aDialogs[6], oSize)         //--Folder File Explorer
    FolderMon(oFol:aDialogs[7], oSize, oDlg)
    FolderService(oFol:aDialogs[8], oSize)
    FolderErro(oFol:aDialogs[09], oSize)        //--Folder Error
    FolderB64(oFol:aDialogs[10], oSize)        //--Folder Base64 Converter
    FolderSX6(oFol:aDialogs[11], oSize)        //--Folder manutenção Grupo

    If lInit
        DEFINE MESSAGE BAR oMsgBar OF oDLG PROMPT "TIDev " COLOR RGB(116,116,116) FONT oFont
        DEFINE MSGITEM oMsgIt of oMsgBar PROMPT "Empresa/Filial: ["+cEmpAnt+"/"+cFilAnt+"] " SIZE 100  ACTION InitEmp(aEmpExQr, oMsgIt, .T., oDlg, oFol )
        DEFINE MSGITEM oMsgIt2 of oMsgBar PROMPT GetEnvServer() SIZE 100
        ACTIVATE MSDIALOG oDlg  ON INIT (lOk:= InitEmp(aEmpExQr, oMsgIt, .T., oDlg, oFol ))
    Else
        ACTIVATE MSDIALOG oDlg
    EndIf
    SetKey(VK_F6 , oKf6)
    If lInit
        RpcClearEnv()
    EndIf


    Set(11,If(lSetAnt,"on","off"))
    LimpaTmp()

Return

    Static __cSeqAliasTmp := "000"

Static Function MyNextAlias()

    __cSeqAliasTmp := Soma1(__cSeqAliasTmp)

Return  "TI" + Strzero(ThreadId(), 6) + __cSeqAliasTmp

Static Function FolderQry(oFol1, oSize, np)
    Local nLin:= 02
    Local nCol:= 02
    Local cQrySup1  := ""
    Local cQrySup2  := ""
    Local nL := oSize:GetDimension("PANEL","COLINI")
    Local nB := oSize:GetDimension("PANEL","LINEND")
    Local nR := oSize:GetDimension("PANEL","COLEND")
    Local nWm := (nR - nL)/2
    Local cAliasExqr := MyNextAlias()
    Local cAliasTst := MyNextAlias()
    Local oBut1
    Local oBut2
    Local oBut3
    Local oBut4
    Local oBut5
    Local oBut6
    Local oBut7
    Local oBut8
    Local oBut9
    Local oButE
    Local oButF
    Local oButG
    Local oPnlQrySup1
    Local oTxtQrySup1
    Local oPnlQrySup2
    Local oTxtQrySup2
    Local oPnlQryI
    Local oPanelS
    Local oPanelM1
    Local oPanelM2
    Local oPanelM3
    Local oSplitH
    Local oSplitV

    Local oTime
    Local cTime		:= "00:00:00 "
    Local oQtd
    Local cQtd      := ""

    oPanelS := TPanelCss():New(,,,oFol1)
    oPanelS :SetCoors(TRect():New( 0,0, nB * 0.4, nR))
    oPanelS :Align :=CONTROL_ALIGN_ALLCLIENT

    oPnlQrySup1:= TPanelCss():New(,,,oPanelS)
    oPnlQrySup1:SetCoors(TRect():New( 0,0, nB * 0.4 , nR * 0.5))
    oPnlQrySup1:Align :=CONTROL_ALIGN_ALLCLIENT

    oPanelM1 := TPanelCss():New(,,,oPnlQrySup1)
    oPanelM1 :SetCoors(TRect():New( 0,0, 25, 25))
    oPanelM1 :Align := CONTROL_ALIGN_TOP
    @ nLin, nCol	 BUTTON oBut1 PROMPT '&Executar'     SIZE 045,010 ACTION ApQry2Run(cQrySup1, cAliasExqr, cAliasTst, oPnlQryI, np, oTime, oQtd)                         OF oPanelM1 PIXEL ; oBut1:nClrText :=0
    @ nLin, nCol+=50 BUTTON oBut2 PROMPT 'Abrir'         SIZE 045,010 ACTION FileQry(.T., @cQrySup1)                    OF oPanelM1 PIXEL ; oBut2:nClrText :=0
    @ nLin, nCol+=50 BUTTON oBut3 PROMPT 'Salvar'        SIZE 045,010 ACTION FileQry(.F., @cQrySup1)                    OF oPanelM1 PIXEL ; oBut3:nClrText :=0
    @ nLin, nCol+=50 BUTTON oBut4 PROMPT 'Change Query'  SIZE 045,010 ACTION cQrySup1 := ChangeQuery(cQrySup1)          OF oPanelM1 PIXEL ; oBut4:nClrText :=0
    @ nLin, nCol+=50 BUTTON oBut5 PROMPT 'SQL to ADVPL'  SIZE 045,010 ACTION cQrySup2 := SQL2ADVPL(@cQrySup1)           OF oPanelM1 PIXEL ; oBut5:nClrText :=0
    @ nLin, nCol+=50 BUTTON oBut8 PROMPT 'Format SQL'    SIZE 045,010 ACTION cQrySup1 := Format(cQrySup1)               OF oPanelM1 PIXEL ; oBut8:nClrText :=0
    @ nLin, nCol+=50 BUTTON oBut9 PROMPT 'Histórico'     SIZE 045,010 ACTION Tools(@cQrySup1, oBut9, np)                OF oPanelM1 PIXEL ; oBut9:nClrText :=0

    oTxtQrySup1 := NewMemo(@cQrySup1,oPnlQrySup1)

    oPnlQrySup2:= TPanelCss():New(,,,oPanelS)
    oPnlQrySup2:SetCoors(TRect():New( 0,0, nB * 0.4, (nR * 0.5)-4))
    oPnlQrySup2:Align :=CONTROL_ALIGN_RIGHT
    oPnlQrySup2:lVisibleControl:= .F.

    @ 000,000 BUTTON oSplitV PROMPT "*" SIZE 4,4 OF oPanelS PIXEL
    oSplitV:cToolTip := "Habilita e desabilita Advpl-SQL"
    oSplitV:bLClicked := {|| oPnlQrySup2:lVisibleControl := !oPnlQrySup2:lVisibleControl }
    oSplitV:Align := CONTROL_ALIGN_RIGHT
    oSplitV:nClrText :=0

    oPanelM2 := TPanelCss():New(,,,oPnlQrySup2)
    oPanelM2 :SetCoors(TRect():New( 0,0, 25, 25))
    oPanelM2 :Align:= CONTROL_ALIGN_TOP
    @ nLin, 02 BUTTON oBut6 PROMPT 'ADVPL to SQL' SIZE 045,010 ACTION cQrySup1 := ADVPL2SQL(@cQrySup2)           OF oPanelM2 PIXEL ; oBut6:nClrText :=0
    @ nLin, 52 BUTTON oBut7 PROMPT 'Trim ADVPL'   SIZE 045,010 ACTION cQrySup2 := QryTrim(cQrySup2)              OF oPanelM2 PIXEL ; oBut7:nClrText :=0
    oTxtQrySup2 := NewMemo(@cQrySup2,oPnlQrySup2)

    oPnlQryI := TPanelCss():New(,,,oFol1)
    oPnlQryI :SetCoors(TRect():New( 0,0, nB * 0.6, nR))
    oPnlQryI :Align :=CONTROL_ALIGN_BOTTOM

    oPanelM3 := TPanelCss():New(,,,oPnlQryI)
    oPanelM3 :SetCoors(TRect():New( 0,0, 25, 25))
    oPanelM3 :Align:= CONTROL_ALIGN_TOP
    @ nLin, 002	 BUTTON oButE PROMPT 'CSV'    SIZE 045,010 ACTION ExportCSV(cAliasTst)  OF oPanelM3 PIXEL ; oButE:nClrText :=0
    @ nLin, 052	 BUTTON oButF PROMPT 'Excel'  SIZE 045,010 ACTION ExportExcel(cAliasTst)  OF oPanelM3 PIXEL ; oButF:nClrText :=0
    @ nLin, 102	 BUTTON oButG PROMPT 'Count'  SIZE 045,010 ACTION CountQuery(cQrySup1, oQtd)  OF oPanelM3 PIXEL ; oButG:nClrText :=0

    @ nLin, nWm - 200 SAY "Quantidade: "       SIZE 030,010 OF oPanelM3 PIXEL
    @ nLin, nWm - 150 SAY oQtd VAR cQtd        SIZE 040,010 OF oPanelM3 PIXEL
    @ nLin, nWm - 100 SAY "Run Time: "   SIZE 030,010 OF oPanelM3 PIXEL
    @ nLin, nWm - 75 SAY oTime VAR cTime SIZE 070,010 OF oPanelM3 PIXEL

    @ 000,000 BUTTON oSplitH PROMPT "*" SIZE 5,5 OF oFol1 PIXEL
    oSplitH:cToolTip := "Habilita e desabilita browser"
    oSplitH:bLClicked := {|| oPnlQryI:lVisibleControl 	:= !oPnlQryI:lVisibleControl}
    oSplitH:Align := CONTROL_ALIGN_BOTTOM
    oSplitH:nClrText :=0

Return

Static Function FolderDic(oFol2, oSize, np)
    Local nLin:= 02
    Local nCol:= 02
    Local nB := oSize:GetDimension("PANEL", "LINEND")
    Local nR := oSize:GetDimension("PANEL", "COLEND")
    Local cAliasDic := Space(3)
    Local oPnlDicI

    Local oBut
    Local oBut1
    Local oBut2
    Local oBut3
    Local oCheck
    Local oCheck2
    Local oPanelM1

    oPanelM1 := TPanelCss():New(,,,oFol2)
    oPanelM1 :SetCoors(TRect():New( 0,0, 30, 30))
    oPanelM1 :Align := CONTROL_ALIGN_TOP

    @ 05,002 SAY "Alias:"  of oPanelM1 SIZE 030,09 PIXEL
    @ 02,025 GET cAliasDic of oPanelM1 SIZE 015,09 PIXEL PICTURE "@!"
    nCol := 50
    @ nLin, nCol     BUTTON oBut  PROMPT '&Executar'      SIZE 045,010 ACTION DicQry(cAliasDic, oPnlDicI, np) OF oPanelM1 PIXEL; oBut:nClrText :=0
    @ nLin, nCol+=50 BUTTON oBut1 PROMPT 'Validar Sx'    SIZE 045,010 ACTION DicTst(cAliasDic, oPnlDicI) OF oPanelM1 PIXEL WHEN cAliasDic <> "SX3"; oBut1:nClrText :=0
    @ nLin, nCol+=50 BUTTON oBut2 PROMPT 'Sync SX3 = DB' SIZE 045,010 ACTION AtuSX3toDB(cAliasDic, oPnlDicI, np) OF oPanelM1 PIXEL WHEN cAliasDic <> "SX3"; oBut2:nClrText :=0
    @ nLin, nCol+=50 BUTTON oBut3 PROMPT 'Estrutura'      SIZE 045,010 ACTION Estru(cAliasDic, oPnlDicI, np) OF oPanelM1 PIXEL WHEN cAliasDic <> "SX3"; oBut3:nClrText :=0
    @ nLin, nCol+=50 CHECKBOX oCheck2 VAR lDeleOn	 PROMPT 'Dele ON'	   SIZE 055,010 OF oPanelM1 PIXEL VALID  DelOn(np)
    @ nLin, nCol+=50 CHECKBOX oCheck VAR lReadOnly	 PROMPT 'Somente Leitura'	 SIZE 055,010 OF oPanelM1 PIXEL

    oPnlDicI := TPanelCss():New(,,,oFol2)
    oPnlDicI :SetCoors(TRect():New( 0,0, nB , nR))
    oPnlDicI :Align :=CONTROL_ALIGN_ALLCLIENT


Return



Static Function DelOn(np)

    If lDeleOn
        Set(11,"on")
    Else
        Set(11,"off")
    EndIf

    If ValType(aDicBrw[np])=='O'
        aDicBrw[np]:Refresh()
    EndIf

Return .t.

Static Function FolderInsp(oFol, oSize)
    Local nB := oSize:GetDimension("PANEL", "LINEND")
    Local nR := oSize:GetDimension("PANEL", "COLEND")
    Local oBut
    Local oBut2
    LOcal oPanelM1
    Local oCheck
    Local oPnlInfI
    Local oPnlInfI2
    Local cFunInf := Space(30)
    Local cObjInf := Space(255)

    oPanelM1 := TPanelCss():New(,,,oFol)
    oPanelM1 :SetCoors(TRect():New( 0,0, 60, 60))
    oPanelM1 :Align := CONTROL_ALIGN_TOP


    @ 003, 002 SAY "Função:" of oPanelM1 SIZE 030, 09 PIXEL
    @ 003, 025 GET cFunInf   of oPanelM1 SIZE 060, 08 PIXEL
    @ 003, 090 BUTTON   oBut				PROMPT 'Pesquisar' SIZE 045,010 ACTION PesqFunc(cFunInf, oPnlInfI, oPnlInfI2) OF oPanelM1 PIXEL ; oBut:nClrText :=0
    @ 003, 150 CHECKBOX oCheck VAR lRPO	    PROMPT 'RPO'	   SIZE 030,010 OF oPanelM1 PIXEL
    @ 003, 180 CHECKBOX oCheck VAR lADVPL	PROMPT 'ADVPL'     SIZE 030,010 OF oPanelM1 PIXEL
    @ 003, 210 CHECKBOX oCheck VAR lClasse  PROMPT 'CLASSE'    SIZE 030,010 OF oPanelM1 PIXEL

    @ 18, 002 SAY "Objeto:" of oPanelM1 SIZE 030, 09 PIXEL
    @ 18, 025 GET  cObjInf  of oPanelM1 SIZE 255, 08 PIXEL
    @ 18, 290 BUTTON   oBut2				 PROMPT 'Pesquisar' SIZE 045,010 ACTION ObjInfo(cObjInf, oPnlInfI2)  OF oPanelM1 PIXEL           ; oBut2:nClrText :=0

    oPnlInfI:= TPanelCss():New(,,,oFol)
    oPnlInfI:SetCoors(TRect():New( 0,0, nB * 0.4 , nR * 0.5))
    oPnlInfI:Align :=CONTROL_ALIGN_ALLCLIENT

    oPnlInfI2:= TPanelCss():New(,,,oFol)
    oPnlInfI2:SetCoors(TRect():New( 0,0, nB * 0.4, nR * 0.5))
    oPnlInfI2:Align :=CONTROL_ALIGN_RIGHT

Return

Static Function FolderCmd(oFol4, oSize)
    Local nLin:= 02
    Local nCol:= 02
    Local nM := 3
    Local nT := oSize:GetDimension("PANEL", "LININI")
    Local nL := oSize:GetDimension("PANEL", "COLINI")
    Local nB := oSize:GetDimension("PANEL", "LINEND")
    Local nR := oSize:GetDimension("PANEL", "COLEND")
    Local nWm := (nR - nL)/2
    Local nHm := (nB - nT)/2
    Local oBut
    Local oBut2
    Local cPnlCmdSup:=""
    Local oPnlCmdSup
    Local oPnlCmdI
    Local oTime
    Local cTime		:= "00:00:00 "
    Local oTxtCmdSup
    Local oCheck


    @ nLin, nCol BUTTON oBut PROMPT '&Executar' SIZE 045,010 ACTION ExecMacro(cPnlCmdSup, oPnlCmdI, oTime) OF oFol4 PIXEL; oBut:nClrText :=0
    @ nLin, nCol+=50 BUTTON oBut2 PROMPT 'Histórico'     SIZE 045,010 ACTION Tools2(@cPnlCmdSup, oBut2)   OF oFol4 PIXEL ; oBut2:nClrText :=0
    @ nLin, nWm - 100 SAY "Run Time: "   SIZE 030,010 OF oFol4 PIXEL
    @ nLin, nWm - 75 SAY oTime VAR cTime SIZE 070,010 OF oFol4 PIXEL
    @ nLin, nCol+=50 CHECKBOX oCheck VAR lTrataErro	 PROMPT 'Trata Erro'	 SIZE 055,010 OF oFol4 PIXEL

    oPnlCmdSup := NewPanel(nT + nM, nL + nM, nHm - nM, nR - nM, oFol4)
    oTxtCmdSup := NewMemo(@cPnlCmdSup, oPnlCmdSup)

    oPnlCmdI := NewPanel(nHm + nM, nL + nM, nB - nM- 60, nR - nM, oFol4)

Return

Static Function FolderHtm(oFol5, oSize)
    Local nLin:= 02
    Local nCol:= 02
    Local nM := 3
    Local nT := oSize:GetDimension("PANEL", "LININI")
    Local nL := oSize:GetDimension("PANEL", "COLINI")
    Local nB := oSize:GetDimension("PANEL", "LINEND")
    Local nR := oSize:GetDimension("PANEL", "COLEND")
    Local nHm := (nB - nT)/2
    Local oBut
    Local cPnlCmdSup:=""
    Local oPnlCmdSup
    Local oPnlCmdI
    Local oTxtCmdSup
    Local oEdit

    @ nLin, nCol BUTTON oBut PROMPT '&Executar' SIZE 045,010 ACTION ExecHtml(cPnlCmdSup, oEdit ) OF oFol5 PIXEL; oBut:nClrText :=0
    //@ nLin, nCol+=50 BUTTON oBut2 PROMPT 'Histórico'     SIZE 045,010 ACTION Tools2(@cPnlCmdSup, oBut2)   OF oFol5 PIXEL ; oBut2:nClrText :=0

    oPnlCmdSup := NewPanel(nT + nM, nL + nM, nHm - nM, nR - nM, oFol5)
    oTxtCmdSup := NewMemo(@cPnlCmdSup, oPnlCmdSup)

    oPnlCmdI := NewPanel(nHm + nM, nL + nM, nB - nM- 60, nR - nM, oFol5)
    @ 0,0 SCROLLBOX oSbr HORIZONTAL SIZE 94,206 OF oPnlCmdI BORDER
    oSbr:Align := CONTROL_ALIGN_ALLCLIENT
    oEdit:= TSimpleEditor():New( 0,0,oSbr,3000,184 )
    oEdit:Align := CONTROL_ALIGN_LEFT

Return

Static Function ExecHtml(cTrb, oEdit)

    oEdit:Load(cTrb)
    oEdit:Refresh()

Return

Static Function FolderExp(oFol6, oSize)
    Local nLin:= 02
    Local nCol:= 02
    Local nT := oSize:GetDimension("PANEL", "LININI")
    Local nL := oSize:GetDimension("PANEL", "COLINI")
    Local nB := oSize:GetDimension("PANEL", "LINEND")
    Local nR := oSize:GetDimension("PANEL", "COLEND")
    Local nWm := (nR - nL)/2
    Local nHm := (nB - nT)/2
    Local nS1 := 0
    Local oList01
    Local oList02
    Local oGet1
    Local oGet2
    Local oBmp01
    Local oBmp02
    Local cPath01 := PadR("C:\",60)
    Local cPath02 := PadR("\",60)
    Local cSearch01 := Space(200)
    Local cSearch02 := Space(200)

    /*

    oPnlFExp := TPanelCss():New(,,, oFol6)
	oPnlFExp:Align := CONTROL_ALIGN_ALLCLIENT
*/
    oPnlFExp := oFol6
    nS1:= (nWm - nCol) / 2 // ao definir os pixels é necessário dividir o valor por dois

    @ nLin     , nCol     MSGET  oGet1  VAR cPath01   PICTURE "@!" PIXEL SIZE nS1-35,009 WHEN .F.  OF oPnlFExp
    @ nLin     , nS1 - 30 BITMAP oBmp01 NAME "OPEN"   SIZE 015,015 OF oPnlFExp PIXEL NOBORDER ON CLICK ( cPath01 := OpenBtn(cPath01,"T") , LeDirect(@oList01,@oGet1,@cPath01) )
    @ nLin+=12 , nCol     MSGET  oGet1  VAR cSearch01 PICTURE "@!" PIXEL SIZE nS1-35,009  OF oPnlFExp
    @ nLin     , nS1 - 30 BITMAP oBmp01 NAME "LUPA"   SIZE 015,015 OF oPnlFExp PIXEL NOBORDER ON CLICK ( FAtualiz(cSearch01,oList01,2) )

    @ nLin+=12 , nCol LISTBOX oList01 FIELDS HEADER " ","File Name","File Size","File Date","File Hour"  SIZE nS1 -15,nHm-49 OF oPnlFExp PIXEL COLSIZES 05,185,35,30,30 ;
        ON DBLCLICK LeDirect(@oList01,@oGet1,@cPath01,.T.)

    nLin:= nHm-20

    @ nLin,nCol     BITMAP oBmp01 NAME "BMPDEL"    SIZE 015,015 OF oPnlFExp PIXEL NOBORDER ON CLICK MsgRun("Apagando Arquivo...","Aguarde.",{|| FApaga(cPath01,oList01) , LeDirect(@oList01,@oGet1,@cPath01) })
    @ nLin,nCol+=15 BITMAP oBmp01 NAME "SDUDRPTBL" SIZE 015,015 OF oPnlFExp PIXEL NOBORDER ON CLICK Processa({|| FApaga(cPath01,oList01,.T.), LeDirect(@oList01,@oGet1,@cPath01) },"Exclusão de arquivos","Excluindo",.T.)
   // @ nLin,nCol+=30 BITMAP oBmp01 NAME "BMPDEL"    SIZE 015,015 OF oPnlFExp PIXEL NOBORDER ON CLICK MsgRun("Apagando Arquivo...","Aguarde.",{|| FApagaDel(cPath01,oList01) , LeDirect(@oList01,@oGet1,@cPath01) })

    nCol := nWm/2 - 7
    nLin := nHm/2 - 87.5

    @ nLin      , nCol BITMAP oBmp01 NAME "RIGHT"   SIZE 015,015 OF oPnlFExp PIXEL NOBORDER ON CLICK MsgRun("Copiando Arquivo...","Aguarde.",{|| FCopia(cPath01,cPath02,oList01) , LeDirect(@oList01,@oGet1,@cPath01),  LeDirect(@oList02,@oGet2,@cPath02) })
    @ nLin += 20, nCol BITMAP oBmp01 NAME "LEFT"    SIZE 015,015 OF oPnlFExp PIXEL NOBORDER ON CLICK MsgRun("Copiando Arquivo...","Aguarde.",{|| FCopia(cPath02,cPath01,oList02) , LeDirect(@oList01,@oGet1,@cPath01),  LeDirect(@oList02,@oGet2,@cPath02) })
    @ nLin += 20, nCol BITMAP oBmp01 NAME "RIGHT_2" SIZE 015,015 OF oPnlFExp PIXEL NOBORDER ON CLICK Processa({|| FCopia(cPath01,cPath02,oList01,.T.), LeDirect(@oList01,@oGet1,@cPath01), LeDirect(@oList02,@oGet2,@cPath02) },"Copia de arquivos","Copiando",.T.)
    @ nLin += 20, nCol BITMAP oBmp01 NAME "LEFT2"   SIZE 015,015 OF oPnlFExp PIXEL NOBORDER ON CLICK Processa({|| FCopia(cPath02,cPath01,oList02,.T.), LeDirect(@oList01,@oGet1,@cPath01), LeDirect(@oList02,@oGet2,@cPath02) },"Copia de arquivos","Copiando",.T.)
    @ nLin += 20, nCol BITMAP oBmp01 NAME "FILTRO"  SIZE 015,015 OF oPnlFExp PIXEL NOBORDER ON CLICK ( MaskDir() , LeDirect(@oList01,@oGet1,@cPath01), LeDirect(@oList02,@oGet2,@cPath02) )

    nLin := 02
    nCol += 20

    @ nLin    , nCol			MSGET  oGet2  VAR cPath02   PICTURE "@!" PIXEL SIZE nS1 -35,009 WHEN .F.  OF oPnlFExp
    @ nLin    , nCol+nS1-32 	BITMAP oBmp02 NAME "OPEN"   SIZE 015,015 OF oPnlFExp PIXEL NOBORDER ON CLICK ( cPath02 := OpenBtn(cPath02,"S") , LeDirect(@oList02,@oGet2,@cPath02) )
    @ nLin+=12, nCol			MSGET  oGet2  VAR cSearch02 PICTURE "@!" PIXEL SIZE nS1 -35,009  OF oPnlFExp
    @ nLin    , nCol+nS1-32 	BITMAP oBmp02 NAME "LUPA"   SIZE 015,015 OF oPnlFExp PIXEL NOBORDER ON CLICK ( FAtualiz(cSearch02,oList02,2) )

    @ nLin+=12, nCol LISTBOX oList02 FIELDS HEADER " ","File Name","File Size","File Date","File Hour" SIZE nS1 -15,nHm-49 OF oPnlFExp PIXEL COLSIZES 05,185,35,30,30 ;
        ON DBLCLICK LeDirect(@oList02,@oGet2,@cPath02,.T.) //ON CHANGE Teste()

    nLin:= nHm-20

    @ nLin,nCol     BITMAP oBmp01 NAME "BMPDEL"    SIZE 015,015 OF oPnlFExp PIXEL NOBORDER ON CLICK MsgRun("Apagando Arquivo...","Aguarde.",{|| FApaga(cPath02,oList02) , LeDirect(@oList02,@oGet2,@cPath02) })
    @ nLin,nCol+=15 BITMAP oBmp01 NAME "SDUDRPTBL" SIZE 015,015 OF oPnlFExp PIXEL NOBORDER ON CLICK Processa({|| FApaga(cPath02,oList02,.T.), LeDirect(@oList02,@oGet2,@cPath02) },"Exclusão de arquivos","Excluindo",.T.)

    LeDirect(@oList01,@oGet1,@cPath01)
    LeDirect(@oList02,@oGet2,@cPath02)

Return


Static Function SetFolder(nFolder)

    lDic := nFolder == 2

    If oTimer == NIL
        Return
    EndIf
    If nFolder == 7
        oTimer:Activate()
    Else
        oTimer:DeActivate()
    EndIf
Return

Static Function ChkErr(oErroArq, lTrataVar)
    Local ni:= 0

    If lTrataVar
        If "variable does not exist " $ oErroArq:description
            cErroA := Alltrim(SubStr(oErroArq:description,24)) + " := '' " + CRLF
        Else
            If oErroArq:GenCode > 0
                cErroA := '(' + Alltrim( Str( oErroArq:GenCode ) ) + ') : ' + AllTrim( oErroArq:Description ) + CRLF
            EndIf
        EndIf
    Else
        If oErroArq:GenCode > 0
            cErroA := '(' + Alltrim( Str( oErroArq:GenCode ) ) + ') : ' + AllTrim( oErroArq:Description ) + CRLF
        EndIf
        ni := 2
        While ( !Empty(ProcName(ni)) )
            cErroA +=	Trim(ProcName(ni)) +"(" + Alltrim(Str(ProcLine(ni))) + ") " + CRLF
            ni++
        End
    EndIf
    Break
Return


/*{Protheus.doc} ExecMacro
@author Izac
@since 18/06/2014
@version 1.0
@param cTrb, character
@return cRet, character
*/
Static Function ExecMacro(cTrb, oPnlCmdI, oTime)
    Local aQry := StrTokArr(cTrb,CRLF)
    Local nX := 0
    Local xAux:=''
    Local cRet:=""
    Local cRetM:= ""
    Local bErroA
    Local cPnlCmdI := ""
    Local oMemErr
    Local nSec1 := 0
    Local nSec2 := 0
    Local nPos
    Local cLinha := ""

    cErroA :=""
    If lTrataErro
        bErroA   := ErrorBlock( { |oErro| ChkErr( oErro ) } )
    EndIf
    Begin Sequence
        nSec1 := Seconds()

        for nX:= 1 to Len(aQry)
            cLinha += AllTrim(aQry[nX])
            // tira o comentario
            nPosC := at("//", cLinha)
            If ! Empty(nPosC)
                cLinha := Left(cLinha, nPosC - 1)
            EndIf
            cLinha := Alltrim(cLinha)
            If empty(cLinha)
                Loop
            EndIf

            If Right(cLinha, 1) == ";"
                cLinha := Left(cLinha, len(cLinha) - 1)
                Loop
            EndIf

            xAux := &(cLinha)
            cLinha := ""

            If Valtype(xAux)=='C'
                cRet:= xAux
            Else
                If ValType(xAux)!= 'U'
                    If ValType(xAux)== 'A'
                        cRet := VarInfo('A',xAux,,.F.)
                    ElseIf ValType(xAux)== 'N'
                        cRet := Alltrim(Str(xAux))
                    ElseIf ValType(xAux)== 'B'
                        cRet := GetCbSource(xAux)
                    Else
                        cRet := AllToChar(xAux)
                    EndIf
                EndIf
            EndIf
            cRetM += Valtype(xAux) + ' -> ' + cRet + CRLF
        next
        nSec2 := Seconds()
        oTime:SetText( APSec2Time(nSec2-nSec1) + " (" + Alltrim(Str(nSec2-nSec1)) + " segs.)" )

        nPos := aScan(aCmdHst, {|x| x == cTrb})
        If Empty(nPos)
            aAdd(aCmdHst, cTrb)
        Else
            aDel(aCmdHst,nPos)
            aCmdHst[len(aCmdHst)] := cTrb
        EndIf
        SaveJson()

    End Sequence
    If lTrataErro
        ErrorBlock( bErroA )
    EndIf

    If ! Empty(cErroA)
        cPnlCmdI := cErroA
        cErroA:= ""
    Else
        cPnlCmdI := cRetM
    EndIf

    @ 0,0 GET oMemErr VAR cPnlCmdI OF oPnlCmdI MEMO size 0,0
    oMemErr:Align := CONTROL_ALIGN_ALLCLIENT


Return cRet

/*/{Protheus.doc} DicQry
Consulta no Dicionário.
@author Izac
@since 18/06/2014
@version 1.0
@param cAlias, character, Alias a ser realizada
/*/
Static Function DicQry(cAlias, oPnlDicI, np)
    Local aColunas:={}
    Local nX := 0
    Local cAliasTst := MyNextAlias()
    Local aStruct:= {}
    Local bErroA
    Local cErro := ""
    Local lTermino := .F.


    cErroA :=""

    If empty(cAlias)
        Return
    EndIf

    If empty(cFilAnt) .or. empty(cEmpAnt)
        MsgInfo("Ambiente Não Inicializado")
        Return
    EndIf

    If ValType(aDicBrw[np])=='O'
        aDicBrw[np]:DeActivate(.T.)
    EndIf

    If cAlias $ "SIX,SX1,SX2,SX3,SX5,SX6,SX7,SXA,SXB,SXE,SXF,SXG"
        cAliasTst := cAlias
    Else
        aAliasDic[np] := MyNextAlias()
        cAliasTst := aAliasDic[np]

        If Select(cAliasTst) > 0
            (cAliasTst)->(DbCloseArea())
        EndIf
        ChkFile(cAlias, .F., cAliasTst)
    EndIf

    bErroA := ErrorBlock( { |oErro| ChkErr( oErro ) } )
    Begin Sequence

        aDicBrw[np] := FWBrowse():New(oPnlDicI)
        aDicBrw[np]:SetDataTable(.T.)
        aDicBrw[np]:SetAlias(cAliasTst)
        aDicBrw[np]:SetDescription("Dicionario")
        aDicBrw[np]:SetUpdateBrowse({||.T.})
        aDicBrw[np]:SetEditCell(.T.,{||.F.})
        aDicBrw[np]:Setdoubleclick({|o| AltReg(o, cAliasTst, .F.)})
        aDicBrw[np]:SetSeek()
        aDicBrw[np]:SetDBFFilter()
        aDicBrw[np]:SetUseFilter()
        aDicBrw[np]:SetBlkColor({|| If(Deleted()    , CLR_WHITE    , CLR_BLACK)})  // cor da fonte
        aDicBrw[np]:SetBlkBackColor({|| If(Deleted(), CLR_LIGHTGRAY,  CLR_WHITE)}) // cor do fundo


        aColunas := {}
        aStruct := ((cAliasTst)->(dbStruct()))
        For nX := 1 To len(aStruct)
            oCol := FWBrwColumn():New()
            oCol:SetTitle(aStruct[nX][1])
            oCol:SetType(aStruct[nX][2])
            oCol:SetSize(aStruct[nX][3])
            oCol:SetDecimal(aStruct[nX][4])
            oCol:SetData(&('{||'+ aStruct[nX][1]+'}'))
            aAdd(aColunas,oCol)
        Next

        oCol := FWBrwColumn():New()
        oCol:SetTitle('RECNO')
        oCol:SetData({||Recno()})
        aAdd(aColunas,oCol)

        aDicBrw[np]:SetColumns(aColunas)
        aDicBrw[np]:Activate()
        lTermino := .t.
    End Sequence
    ErrorBlock( bErroA )

    If ! Empty(cErroA) .and. ! lTermino
        cErro := cErroA
        AutoGrLog("")
        FErase(NomeAutoLog())
        AutoGrLog(cErro)
        MostraErro()
        cErroA :=""
    EndIf
Return

/*{Protheus.doc} AltReg

@author Izac
@since 02/07/2014
@version 1.0
@param oObject, objeto
*/

Static Function AltReg(oObject, cAliasAlt, lQuery)
    Local oDlgReg
    Local nLin
    Local nCol
    Local cField
    Local lRet     := .F.
    Local xValue

    If lQuery
        nLin := oObject:nat
        nCol := oObject:ncolpos
        //cField := oObject:aColumns[nCol]:cheading
        cField := "Cmp"+StrZero(nCol, 3)
        xValue:= (cAliasAlt)->&(cField)
        lReadOnly := .T.
    Else
        nLin := oObject:At()
        nCol := oObject:ColPos()
        cField := oObject:aColumns[nCol]:cTitle
        xValue:= (cAliasAlt)->&(cField)
    EndIf


    DEFINE MSDIALOG oDlgReg FROM 0,0 TO 25,260 TITLE "Valor" PIXEL
    oGet:=TGet():New(02,02, bSETGET(xValue),oDlgReg,100,0009,,,,,,,,.T.)
    If ! lReadOnly .and. lDic
        DEFINE SBUTTON FROM 2,103 TYPE 1 OF oDlgReg ENABLE ACTION (lRet := .T.,oDlgReg:End())
    EndIf
    ACTIVATE MSDIALOG oDlgReg CENTERED

    If ! lReadOnly .and. lDic .and. lRet
        If !IsLocked(cAliasAlt)
            (cAliasAlt)->(RecLock(cAliasAlt, .F.))
            (cAliasAlt)->&(cField):= xValue
            (cAliasAlt)->(MsUnlock())
        Else
            MsgInfo("Não foi possível alterar!","Registro lockado")
        EndIf
    EndIf
Return

Static Function ApQry2Run(cQuery, cAliasExqr, cAliasTst, oPnlQryI, np, oTime, oQtd)

    MsgRun("Executando query...","Aguarde..." , {|| PApQry2Run(cQuery, cAliasExqr, cAliasTst, oPnlQryI, np, oTime, oQtd) } )

Return

Static Function PApQry2Run(cQuery, cAliasExqr, cAliasTst, oPnlQryI, np, oTime, oQtd)
    Local nX := 0

    Local aStruct:= {}
    Local cTst := ''
    Local bErroA
    Local cErro:= ''

    Local aArea := {}
    Local nSec1 := 0
    Local nSec2 := 0
    Local cComando:=""
    Local nPos
    Local aComando:={}
    Local cNoSelect:= ""
    Local cDir
    Local aEstruAux := {}

    cQuery:= UPPER(ALLTRIM(cQuery))

    If empty(cQuery)
        Return
    EndIf

    If empty(cFilAnt) .or. empty(cEmpAnt)
        MsgInfo("Ambiente Não Inicializado")
        Return
    EndIf

    cComando := Left(cQuery, At(" ",cQuery) -1)

    If ! cComando == "SELECT" .and. ! MsgNoYes('Confirma a execução do ' + cComando+ ' no banco?','Atenção')
        Return
    EndIf


    aArea := GetArea()
    If Valtype(aQryBrw[np])=='O'
        aQryBrw[np]:Hide()
        aQryBrw[np]:FreeChildren()
    EndIf

    If Select(cAliasExqr) > 0
        (cAliasExqr)->(DbCloseArea())
    EndIf

    If Select(cAliasTst) > 0
        (cAliasTst)->(DbCloseArea())
    EndIf

    cErroA :=""
    bErroA	:= ErrorBlock( { |oErro| ChkErr( oErro ) } )
    Begin Sequence
        If ! cComando == "SELECT"
            cNoSelect := strtran(cQuery,CRLF,'')
            cNoSelect := AllTrim(cNoSelect)
            If Right(cNoSelect,1) == ";"
                cNoSelect := left(cNoSelect,Len(cNoSelect) - 1)
            EndIf
            aComando := StrTokArr(cNoSelect, ";")
            For nx:= 1 to len(aComando)
                nSec1 := Seconds()
                If TcSqlExec(aComando[nx]) < 0
                    cErroA:="TCSQLError() " + TCSQLError()
                    Break
                EndIf
            Next
            TcSQLExec( "COMMIT" )

            nSec2 := Seconds()
            oTime:SetText( APSec2Time(nSec2-nSec1) + " (" + Alltrim(Str(nSec2-nSec1)) + " segs.)" )
            MsgAlert("Query executada!" + CRLF + "Tempo de processamento:" + APSec2Time(nSec2-nSec1) + " (" + Alltrim(Str(nSec2-nSec1)) + " segs.)" + CRLF + " Comandos processados:" + AllTrim(Str(len(aComando))))
        Else
            cTst := cQuery
            nSec1 := Seconds()
            dbUseArea(.T.,'TOPCONN', TCGenQry(,,cTst),cAliasTst, .F., .T.)
            nSec2 := Seconds()
            oTime:SetText( APSec2Time(nSec2-nSec1) + " (" + Alltrim(Str(nSec2-nSec1)) + " segs.)" )
            oQtd:SetText( "" )
            aStruct := (cAliasTst)->(dbStruct())

            For nx:= 1 to len(aStruct)
                If aStruct[nx,2] == "N"
                    aStruct[nx,3] := 30
                EndIf
            Next

            cDir := "system\tidev\"
            If ! ExistDir(cDir)
                MakeDir(cDir)
            Endif

            For nx:= 1 to len(aStruct)
                aadd(aEstruAux, {"Cmp"+StrZero(nx, 3) , aStruct[nx, 2], aStruct[nx, 3], aStruct[nx, 4]}  )
            Next

            dbCreate(cDir + cAliasExqr, aEstruAux )
            dbUseArea( .T., "DBFCDX", cDir + cAliasExqr, cAliasExqr, .F., .F. )

            aQryBrw[np] := MsBrGetDBase():New(1, 1, __DlgWidth(oPnlQryI)-1, __DlgHeight(oPnlQryI) - 1,,,, oPnlQryI,,,,,,,,,,,, .F., cAliasExqr, .T.,, .F.,,,)
            For nX:=1 To (cAliasExqr)->(FCount())
                aQryBrw[np]:AddColumn( TCColumn():New( aStruct[nx, 1] , &("{ || " + cAliasExqr + "->" + (cAliasExqr)->(FieldName(nX)) + "}"),,,,, "LEFT") )
            Next nX

            ApQryPutInFile(cAliasTst, cAliasExqr)

            aQryBrw[np]:lColDrag	:= .T.
            aQryBrw[np]:lLineDrag	:= .T.
            aQryBrw[np]:lJustific	:= .T.
            aQryBrw[np]:nColPos		:= 1
            aQryBrw[np]:Cargo		:= {|| __NullEditcoll()}
            aQryBrw[np]:bSkip		:= &("{|N| ApQryPutInFile('"+cAliasTst+"', '"+cAliasExqr+"', N), "+cAliasExqr+"->(_DBSKIPPER(N))}")
            aQryBrw[np]:cCaption	:= APSec2Time(nSec2-nSec1)
            aQryBrw[np]:Align       := CONTROL_ALIGN_ALLCLIENT
            aQryBrw[np]:bLDblClick  := {|| AltReg(aQryBrw[np], cAliasExqr, .T.)}

        EndIf
        nPos:=aScan(aQryHst[np], {|x| x == cQuery})
        If  Empty(nPos)
            aAdd(aQryHst[np], cQuery)
        Else
            aDel(aQryHst[np], nPos)
            aQryHst[np, len(aQryHst[np])] := cQuery
        EndIf
        SaveJson()
    End Sequence
    ErrorBlock( bErroA )

    If ! Empty(cErroA)
        cErro := cErroA
        AutoGrLog("")
        FErase(NomeAutoLog())
        AutoGrLog(cErro)
        MostraErro()
        cErroA :=""
    EndIf
    RestArea(aArea)
Return

Static Function LimpaTmp()
    Local cDir := "system\tidev\"
    Local aDir := {}
    Local cArq := ""
    Local nx   := 0

    If ! ExistDir(cDir)
        Return
    EndIf

    aDir := Directory(cDir + "*.dtc")
    For nx := 1 to len(aDir)
        cArq := aDir[nx, 1]
        FErase(cDir + cArq)
    Next
Return


Static Function ApQryPutInFile(cSource, cTarget, n)
    Local nX
    Local nI		:= 1
    Local nRecno	:= (cTarget)->(Recno())
    Local aFields
    Local nFields

    Default n := __nBuffer

    If (cSource)->(Eof()) .Or. !( n > 0 .And. ( n + (cTarget)->(Recno()) > (cTarget)->(RecCount()) - __nBuffer ) )
        Return
    EndIf

    aFields := (cTarget)->(dbStruct())
    nFields := Len(aFields)

    While (cSource)->(!Eof()) .And. nI <= __nBuffer
        (cTarget)->(dbAppend())
        For nX:=1 To nFields
            If aFields[nX][2] == "N"
                (cTarget)->(fieldput(nX, val(str((cSource)->(Fieldget(nX)), aFields[nX][3], aFields[nX][4]))))
            Else
                //(cTarget)->(FieldPut(nX, (cSource)->&(aFields[nX][1])))
                (cTarget)->(FieldPut(nX, (cSource)->(Fieldget(nX))))
            EndIf
        Next nX
        nI += 1
        (cSource)->(dbSkip())
    End
    (cTarget)->(dbCommit())
    (cTarget)->(dbGoto(nRecno))
Return



Static Function ExportCSV(cAliasTst)
    Local cFile := ""
    Private lAbortPrint := .F.

    If Select(cAliasTst) == 0
        MsgAlert("Execute uma query!!")
        Return .F.
    EndIf

    cFile := cGetFile("Arquivos (*.csv) |*.csv|","Informe o arquivo", 0, "C:\", .F., GETF_LOCALHARD + GETF_LOCALFLOPPY + GETF_NETWORKDRIVE)

    If Empty(cFile)
        Return .F.
    Endif

    If ! Lower(Right(cFile, 4)) == ".csv"
        cFile += ".csv"
    EndIf
    If File(cFile)
        If ! MsgYesNo("Confirma a substituição do arquivo?")
            Return .F.
        EndIf
        FErase(cFile)
    EndIF

    Processa({|| ProcCSV(cAliasTst, cFile)},,,.T.)

    If lAbortPrint
        MsgAlert("Geração .csv interrompida!")
    Else
        MsgAlert("Geração .csv concluida!")
    EndIf

Return

Static Function ProcCSV(cAliasCSV, cArquivo)
    Local cCab  := ""
    Local cLinha:= ""
    Local nx    := 0
    Local nReg  := 0
    Local aFields := (cAliasCSV)->(dbStruct())
    Local nFields := Len(aFields)
    Local nRec := (cAliasCSV)->(Recno())

    For nx:= 1 to nFields
        cCab +=  aFields[nx, 1] + ";"
    Next
    GrvArq(cArquivo, cCab)
    ProcRegua(1)

    (cAliasCSV)->(DbGoTop())
    While (cAliasCSV)->(! Eof())
        IncProc("Processando linha: " + Alltrim(Str(++nReg, 8)))
        ProcessMessage()
        If lAbortPrint
            Return
        EndIf

        cLinha := ""
        For nx:= 1 to nFields
            If aFields[nX][2] == "N"
                cLinha += StrTran(Padl(cValToChar((cAliasCSV)->(FieldGet(nx))) ,20), ".", ",")
            ElseIf aFields[nX][2] == "C"
                cLinha += (cAliasCSV)->(Fieldget(nX))
            ElseIf aFields[nX][2] == "D"
                cLinha += Dtoc((cAliasCSV)->(Fieldget(nX)))
            ElseIf aFields[nX][2] == "L"
                cLinha += If((cAliasCSV)->(Fieldget(nX)), "TRUE","FALSE")
            Else
                cLinha += cValToChar((cAliasCSV)->(FieldGet(nx)))
            EndIf
            cLinha += ";"
        Next
        GrvArq(cArquivo, cLinha)

        (cAliasCSV)->(DbSkip())
    End
    (cAliasCSV)->(DbGoTo(nRec))

Return

Static Function GrvArq(cArquivo,cLinha)
    If ! File(cArquivo)
        If (nHandle2 := MSFCreate(cArquivo,0)) == -1
            Return
        EndIf
    Else
        If (nHandle2 := FOpen(cArquivo,2)) == -1
            Return
        EndIf
    EndIf
    FSeek(nHandle2,0,2)
    FWrite(nHandle2,cLinha+CRLF)
    FClose(nHandle2)
Return

Static Function ExportExcel(cAliasTst)
    Local cFile := ""
    Local oExcel
    Private lAbortPrint := .F.

    If Select(cAliasTst) == 0
        MsgAlert("Execute uma query!!")
        Return .F.
    EndIf

    cFile := cGetFile("Arquivos query (*.xls) |*.xls|","Informe o arquivo", 0, "C:\", .F., GETF_LOCALHARD + GETF_LOCALFLOPPY + GETF_NETWORKDRIVE)
    If Empty(cFile)
        Return .F.
    Endif

    If ! Lower(Right(cFile, 4)) == ".xls"
        cFile += ".xls"
    EndIf
    If File(cFile)
        If ! MsgYesNo("Confirma a substituição do arquivo?")
            Return .F.
        EndIf
        FErase(cFile)
    EndIF

    oExcel:= FWMSEXCEL():New()
    //oExcel:SetTitleBold(.T.)
    //oExcel:SetTitleSizeFont(18)
    //oExcel:SetHeaderBold(.T.)
    //oExcel:SetHeaderSizeFont(14)

    //FWMsExcel():SetFontSize(< nFontSize >) //tamanho
    //FWMsExcel():SetFont(< cFont >) //nome da fonte
    //FWMsExcel():SetTitleFont(< cFont >)
    //FWMsExcel():SetTitleSizeFont(< nFontSize >)
    //FWMsExcel():SetTitleItalic(< lItalic >)
    //FWMsExcel():SetTitleBold(< lBold >)
    //FWMsExcel():SetTitleFrColor(< cColor >) //cor hexadecimal
    //FWMsExcel():SetTitleBgColor(< cColor >)-
    //FWMsExcel():SetHeaderSizeFont(< nFontSize >)
    //FWMsExcel():SetHeaderItalic(< lItalic >)
    //FWMsExcel():SetHeaderBold(< lBold >)
    //FWMsExcel():SetFrColorHeader(< cColor >)
    //FWMsExcel():SetBgColorHeader(< cColor >)
    //FWMsExcel():SetLineFont(< cFont >)
    //FWMsExcel():SetLineSizeFont(< nFontSize >)
    //FWMsExcel():SetLineBgColor(< cColor >)
    //FWMsExcel():Set2LineBgColor(< cColor >)

    Processa({|| oExcel := ProcExcel(oExcel, cAliasTst)},,,.T.)

    If lAbortPrint
        MsgAlert("Geração de planilha Excel interrompida!")
    Else
        oExcel:Activate()
        oExcel:GetXMLFile(cFile)
        ShellExecute("open", cFile, "", "", 1)
        MsgAlert("Geração de planilha Excel concluida!")
    EndIf
    oExcel := FreeObj(oExcel)

Return

Static Function ProcExcel(oExcel, cAliasCSV)
    Local nx      := 0
    Local nReg    := 0
    Local aFields := (cAliasCSV)->(dbStruct())
    Local nFields := Len(aFields)
    Local nRec    := (cAliasCSV)->(Recno())
    Local cPlan   := "Query"
    Local cTit    := "Tabela"
    Local nAlign  := 0
    Local nFormat := 0
    Local lTotal  := .F.
    Local aLinha := {}

    oExcel:AddworkSheet(cPlan)
    oExcel:AddTable (cPlan, cTit)

    For nx:= 1 to nFields
        lTotal  := .F.
        If aFields[nx, 2] == "D"
            nAlign 	:= 2
            nFormat	:= 4
        ElseIf aFields[nx, 2] == "N"
            nAlign 	:= 3
            nFormat	:= 2
            lTotal  := .T.
        Else
            nAlign 	:= 1
            nFormat	:= 1
        EndIf
        //< cWorkSheet >, < cTable >, < cColumn >, < nAlign > //1-Left,2-Center,3-Right, < nFormat > //1-General,2-Number,3-Monetário,4-DateTime, < lTotal >
        oExcel:AddColumn(cPlan, cTit, aFields[nX, 1], nAlign, nFormat, lTotal)
    Next
    ProcRegua(1)
    (cAliasCSV)->(DbGoTop())
    While (cAliasCSV)->(! Eof())
        IncProc("Processando linha: " + Alltrim(Str(++nReg, 8)))
        ProcessMessage()
        If lAbortPrint
            Return oExcel
        EndIf

        aLinha:= {}
        For nx:= 1 to nFields
            aadd(aLinha, (cAliasCSV)->(FieldGet(nx)) )
        Next
        oExcel:AddRow(cPlan, cTit, aLinha)
        (cAliasCSV)->(DbSkip())
    End
    (cAliasCSV)->(DbGoTo(nRec))

Return oExcel

Static Function CountQuery(cQuery, oQtd)

    Local cTst := ''
    Local bErroA
    Local cErro:= ''
    Local aArea := GetArea()
    Local cAliasCount := "TMPCOUNT"
    Local nQtde := 0

    If empty(cQuery)
        Return
    EndIf

    If empty(cFilAnt) .or. empty(cEmpAnt)
        MsgInfo("Ambiente Não Inicializado")
        Return
    EndIf

    cQuery:= UPPER(ALLTRIM(cQuery))
    cQuery:= "SELECT COUNT(*) QTDE FROM ("+cQuery+") "
    If Select(cAliasCount) > 0
        (cAliasCount)->(DbCloseArea())
    EndIf

    cErroA :=""
    bErroA	:= ErrorBlock( { |oErro| ChkErr( oErro ) } )
    Begin Sequence
        cTst := cQuery
        dbUseArea(.T.,'TOPCONN', TCGenQry(,,cTst),cAliasCount, .F., .T.)
        If (cAliasCount)->(! Eof())
            nQtde := (cAliasCount)->QTDE
        EndIf
    End Sequence
    ErrorBlock( bErroA )

    If Select(cAliasCount) > 0
        (cAliasCount)->(DbCloseArea())
    EndIf

    If ! Empty(cErroA)
        cErro := cErroA
        AutoGrLog("")
        FErase(NomeAutoLog())
        AutoGrLog(cErro)
        MostraErro()
        cErroA :=""
    EndIf
    RestArea(aArea)
    oQtd:SetText(Alltrim(Transform(nQtde,"999,999,999")))
Return

/*/{Protheus.doc} PesqFunc
(long_description)
@author Izac
@since 04/09/2014
@version 1.0
@param cFunc, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function PesqFunc(cFunc, oPnlInfI, oPnlInfI2)
    Local aType,aFile,aLine,aDate,aTime
    Local nCount
    Local aDados := {}
    Local aFuns  := {}
    Local aFields:= { 'Função','Tipo','Arquivo','Linha','Data','Hora'}

    If empty(cFunc)
        Return
    EndIf

    If empty(cFilAnt) .or. empty(cEmpAnt)
        MsgInfo("Ambiente Não Inicializado")
        Return
    EndIf

    If Type('oInfBrw')=='O'
        oInfBrw:DeActivate(.T.)
    EndIf
    oInfBrw := FWBrowse():New(oPnlInfI)
    oInfBrw:SetDataArray(.T.)
    oInfBrw:SetDescription("Info")
    oInfBrw:SetUpdateBrowse({||.T.})
    oInfBrw:SetEditCell(.T.,{||.F.})
    oInfBrw:SetDoubleClick({|o|BuscaPar(o, oPnlInfI2 )})
    oInfBrw:SetSeek()
    oInfBrw:SetUseFilter()
    oInfBrw:SetDBFFilter()

    aColunas := {}
    for nCount:= 1 to Len(aFields)
        oCol := FWBrwColumn():New()
        oCol:SetTitle(aFields[nCount])
        oCol:SetData(&("{|x|x:oData:aArray[x:At()]["+Str(nCount)+"]}"))
        aAdd(aColunas,oCol)
    next

    MsgRun("Buscando funções protheus.","Aguarde",{||aFuns := GetFuncArray(Alltrim(cFunc), aType, aFile, aLine, aDate, aTime)})

    If lADVPL
        For nCount := 1 To Len(aFuns)
            AAdd(aDados, { aFuns[nCount], aType[nCount], aFile[nCount], aLine[nCount], aDate[nCount], aTime[nCount]} )
        Next
    EndIf

    lComMask := '*'$cFunc

    cFunc := StrTran(cFunc,"*","")
    cFunc := Upper(AllTrim(cFunc))

    If Empty(aRet__Func)
        aRet__Func:= __FunArr()
    EndIf

    If Empty(aRet__Class)
        aRet__Class:= __ClsArr()
    EndIf

    If lComMask
        If lADVPL
            AEval(aRet__Func,{|x,y|If(Empty(cFunc) .Or. cFunc $ Upper(x[1]),AAdd(aDados, { x[1], "ADVPL", "", "", "", ""}),Nil)})
        EndIf
        If lClasse
            AEval(aRet__Class,{|x,y|If(Empty(cFunc) .Or. cFunc $ Upper(x[1]),AAdd(aDados, { x[1], "Classe", "", "", "", ""}),Nil)})
        EndIf
    Else
        If lADVPL
            If ( nCount := AScan(aRet__Func,{|x| cFunc == Upper(x[1])  }) ) > 0
                AAdd(aDados, { aRet__Func[nCount][1], "ADVPL", "", "", "", ""} )
            EndIf
        EndIf

        If lClasse
            If ( nCount := AScan(aRet__Class,{|x| cFunc == Upper(x[1])  }) ) > 0
                AAdd(aDados, { aRet__Class[nCount][1], "Classe", "", "", "", ""} )
            EndIf
        EndIf
    EndIf

    oInfBrw:SetColumns(aColunas)
    oInfBrw:SetArray(aDados)
    oInfBrw:Activate()
Return

/*/{Protheus.doc} BuscaPar
Busca parametros de uma função específica.
@author Carlos Alberto Gomes Junior
@since 13/02/2014
@version 1.0
@param cNomeFunc, character, Nome da função
@param lAdvpl, logico, Se a função é do Protheus ou do Advpl
@return cRetPar, Descrição dos parametros da função
/*/
Static Function BuscaPar(oObj, oPnlInfI2)

    Local cRet    := ""
    Local cRetPar := ""
    Local cPar    := ""
    Local nX  := 0
    Local nY := 0
    Local nZ := 0
    Local aRet2   := {}
    Local cNomeFunc := oObj:oData:aArray[oObj:At()][1]
    Local lAdvpl    := oObj:oData:aArray[oObj:At()][2] =="ADVPL"
    Local lClasse   := oObj:oData:aArray[oObj:At()][2] =="Classe"
    Local cChamada := 'Chamada: ' +CHR(9)+ cNomeFunc+'( '

    If lClasse
        nX := ascan(aRet__Class,{|x|cNomeFunc $ x[1]})
        cRetPar += 'Classe:' + aRet__Class[nx][1]+CRLF
        If !empty(aRet__Class[nx][2])
            cRetPar += 'Herdada de: ' + aRet__Class[nx][2]+CRLF
        EndIf

        If !empty(aRet__Class[nx][3])
            cRetPar += CRLF
            cRetPar += 'Variáveis: '+CRLF
            for nY:= 1 to Len(aRet__Class[nx][3])
                cRetPar += "   "+aRet__Class[nx][3][nY][1]+CRLF
            next
        EndIf

        If !empty(aRet__Class[nx][4])
            cRetPar += CRLF
            cRetPar += 'Métodos: '+CRLF
            for nY:= 1 to Len(aRet__Class[nx][4])
                cRetPar += "   "+aRet__Class[nx][4][nY][1]+CRLF

                If !empty(aRet__Class[nx][4][nY][2])
                    cRetPar += "    "+"Parâmetros:"+CRLF

                    For nZ:= 1 to len(aRet__Class[nx][4][nY][2]) step 2
                        cPar:=SubStr(aRet__Class[nx][4][nY][2],nZ,2)
                        Do Case
                        Case Left(cPar,1)=='*'
                            cRet:='xExp'+strZero((nZ+1)/2,2)+' - variavel'
                        Case Left(cPar,1)=='C'
                            cRet:='cExp'+strZero((nZ+1)/2,2)+' - caracter'
                        Case Left(cPar,1)=='N'
                            cRet:='nExp'+strZero((nZ+1)/2,2)+' - numerico'
                        Case Left(cPar,1)=='A'
                            cRet:='aExp'+strZero((nZ+1)/2,2)+' - array'
                        Case Left(cPar,1)=='L'
                            cRet:='lExp'+strZero((nZ+1)/2,2)+' - logico'
                        Case Left(cPar,1)=='B'
                            cRet:='bExp'+strZero((nZ+1)/2,2)+' - bloco de codigo'
                        Case Left(cPar,1)=='O'
                            cRet:='oExp'+strZero((nZ+1)/2,2)+' - objeto'
                        EndCase
                        If Right(cPar,1)=='R'
                            cRet+=' [obrigatorio]'
                        ElseIf Right(cPar,1)=='O'
                            cRet+=' [opcional]'
                        EndIf
                        cRetPar += "       "+cRet+CRLF
                    Next nZ

                EndIf
                cRetPar += CRLF
            next
        EndIf
    ElseIf lAdvpl
        nX := ascan(aRet__Func,{|x|cNomeFunc $ x[1]})
        If nX>0
            For nY := 1 to len(aRet__Func[nX][2]) step 2
                cPar := SubStr(aRet__Func[nX][2],nY,2)

                If Right(cPar,1)=='R'
                    cRet:= Chr(9)+' [obrigatorio]'
                ElseIf Right(cPar,1)=='O'
                    cRet:= Chr(9)+' [opcional]'
                EndIf

                Do Case
                Case Left(cPar,1)=='*'
                    cPar:= 'xExp'+strZero((nY+1)/2,2)
                    cRet:= cPar+' - variavel'+cRet
                Case Left(cPar,1)=='C'
                    cPar:= 'cExp'+strZero((nY+1)/2,2)
                    cRet:= cPar+' - caracter'+cRet
                Case Left(cPar,1)=='N'
                    cPar:= 'nExp'+strZero((nY+1)/2,2)
                    cRet:= cPar+' - numerico'+cRet
                Case Left(cPar,1)=='A'
                    cPar:= 'aExp'+strZero((nY+1)/2,2)
                    cRet:= cPar+' - array'+cRet
                Case Left(cPar,1)=='L'
                    cPar:= 'lExp'+strZero((nY+1)/2,2)
                    cRet:= cPar+' - logico'+cRet
                Case Left(cPar,1)=='B'
                    cPar:= 'bExp'+strZero((nY+1)/2,2)
                    cRet:= cPar+' - bloco de codigo'+cRet
                Case Left(cPar,1)=='O'
                    cPar:= 'oExp'+strZero((nY+1)/2,2)
                    cRet:= cPar+' - objeto'+cRet
                EndCase
                cChamada += cPar+', '
                cRetPar += "    Parametro " + cValtoChar((nY+1)/2) + " = " + cRet + CRLF

            Next nY
        EndIf
    Else
        aRet2:= GetFuncPrm(cNomeFunc)

        for nY:= 1 to Len(aRet2)
            cPar:= aRet2[nY]
            Do Case
            Case Left(cPar,1)=='X'
                cRet:=' - variavel'
            Case Left(cPar,1)=='C'
                cRet:=' - caracter'
            Case Left(cPar,1)=='N'
                cRet:=' - numerico'
            Case Left(cPar,1)=='A'
                cRet:=' - array'
            Case Left(cPar,1)=='L'
                cRet:=' - logico'
            Case Left(cPar,1)=='D'
                cRet:=' - data'
            Case Left(cPar,1)=='B'
                cRet:=' - bloco de codigo'
            Case Left(cPar,1)=='O'
                cRet:=' - objeto'
            OtherWise
                cRet:=' - Unknown'
            EndCase
            cChamada += cPar+', '
            cRetPar += "    Parametro " + cValtoChar(nY) + " = " + aRet2[nY]+cRet + CRLF
        Next
    EndIf

    If !lClasse
        If ','$cChamada
            cChamada := SubStr(cChamada,1,Len(cChamada)-2)
        EndIf
        cRetPar := cChamada +' )'+ CRLF + CRLF + cRetPar
    EndIf

    oGet:= tMultiget():new(,,bSETGET(cRetPar),oPnlInfI2)
    oGet:Align := CONTROL_ALIGN_ALLCLIENT

Return
/*/{Protheus.doc} ObjInfo
Retorna as informações do Objeto
@author Izac
@since 23/05/2014
@version 1.0
@param cObj, character, Se Informado tenta criar o objeto a partir de &(cObj+'():New()')
@param oObj, objeto, Se Informado obtém as informações do objeto
@sample U_ObjInfo('FwBrowse')
/*/
Static Function ObjInfo(cObj, oPnlInfI2)
    Local aInfo:={}
    Local nX := 0
    Local nY := 0
    Local cRet:=''
    Local oObj
    Local cObjName:=''
    Local cRetPar :=''
    Local bErroA := ErrorBlock( { |oErro| ChkErr( oErro ) } )


    Begin Sequence

        If !('('$cObj)
            oObj:= &(cObj+'():New()')
        Else
            oObj:= &(cObj)
        EndIf

        If oObj!= Nil .and. ValType(oObj)=='O'
            cObjName:= Alltrim(Upper(GetClassName(oObj)))
            cRetPar += 'Objeto: '+cObjName
            aInfo:= ClassDataArr(oObj,.T.)
            cRetPar += CRLF
            cRetPar += "    "+"Variáveis:"+CRLF

            for nX:= 1 to Len(aInfo)
                cPar:= aInfo[nX][1]
                Do Case
                Case Left(cPar,1)=='*'
                    cRet:=' - variavel'
                Case Left(cPar,1)=='U'
                    cRet:=' - variavel'
                Case Left(cPar,1)=='C'
                    cRet:=' - caracter'
                Case Left(cPar,1)=='N'
                    cRet:=' - numerico'
                Case Left(cPar,1)=='A'
                    cRet:=' - array'
                Case Left(cPar,1)=='L'
                    cRet:=' - logico'
                Case Left(cPar,1)=='B'
                    cRet:=' - bloco de codigo'
                Case Left(cPar,1)=='O'
                    cRet:=' - objeto'
                OtherWise
                    cRet:=' - desconhecido'
                EndCase
                cRet:= "    " + strZero(nx,3)+ "= " + aInfo[nX][1]+cRet

                //			If !empty(aInfo[nX][2])
                //				cRet:= cRet + Chr(9) +" Valor Default: " +CRLF+ VarInfo(ValType(aInfo[nX][2]),aInfo[nX][2],,.F.)
                //			EndIf

                If !empty(aInfo[nX][4]) .and. Alltrim(aInfo[nX][4])!= cObjName
                    cRet:= cRet + Chr(9) + Chr(9) +" Herdado de: " + Alltrim(aInfo[nX][4])
                EndIf

                cRetPar += cRet+CRLF
            next

            aInfo:= ClassMethArr(oObj,.T.)

            for nX:= 1 to Len(aInfo)
                cRetPar += CRLF
                cRetPar += 'Método: '+aInfo[nX][1]+CRLF
                If !empty(aInfo[nX][2])
                    cRetPar += "    "+"Parâmetros:"+CRLF
                    for nY:= 1 to Len(aInfo[nX][2])
                        cPar:= aInfo[nX][2][nY]
                        Do Case
                        Case Left(cPar,1)=='*'
                            cRet:=' - variavel'
                        Case Left(cPar,1)=='U'
                            cRet:=' - variavel'
                        Case Left(cPar,1)=='C'
                            cRet:=' - caracter'
                        Case Left(cPar,1)=='N'
                            cRet:=' - numerico'
                        Case Left(cPar,1)=='A'
                            cRet:=' - array'
                        Case Left(cPar,1)=='L'
                            cRet:=' - logico'
                        Case Left(cPar,1)=='B'
                            cRet:=' - bloco de codigo'
                        Case Left(cPar,1)=='O'
                            cRet:=' - objeto'
                        OtherWise
                            cRet:=' - desconhecido'
                        EndCase
                        cRet:= "    Parametro " + strZero(nY,3)+ "= " + aInfo[nX][2][nY]+cRet
                        cRetPar += cRet+CRLF
                    next
                EndIf
            next

            //--Destroi o Objeto Criado
            FreeObj(oObj)
        Else
            cRetPar := CRLF+'Problemas na inicialização do Objeto.'+CRLF+'Objeto Invalido.'
        EndIf
    End Sequence
    ErrorBlock( bErroA )

    /*
    If ! Empty(cErroA)
        cRetPar := cErroA
        cErroA  := ""
    EndIf
    */
    oGet:= tMultiget():new(,,bSETGET(cRetPar), oPnlInfI2)
    oGet:Align := CONTROL_ALIGN_ALLCLIENT
Return

/*/{Protheus.doc} SQL2ADVPL

@author Izac
@since 02/07/2014
@version 1.0
@param cQuery, character
@return cRet, character,Trecho de código ADVPL
/*/
Static Function SQL2ADVPL(cQuery)
    Local aQry := StrTokArr(cQuery,CRLF)
    Local nX := 0
    Local nY := 0
    Local cAux:=''
    Local cTrb:=''
    Local cRet:=''
    Local aFiliais := {{"000"},{"010"}, {"020"}, {"030"}, {"040"}, {"050"}, {"060"}, {"070"}, {"080"}, {"090"}, {"099"}}

    cRet:= 'cQuery := " "'+CRLF

    for nX:= 1 to Len(aQry)
        cAux := aQry[nX] + Space(1)
        If !empty(cAux)
            cTrb :=''
            for nY:= 1 to Len(cAux)
                If Empty(Substr(cAux,nY,1))
                    If Len(cTrb) == 6 .And. ( nPos := AScan(aFiliais,{|x| x[1] $ cTrb}) ) > 0
                        cTrb := '" + RetSQLName("'+Upper(SubStr(cTrb,1,3))+'") + "'
                        cAux :=  Substr(cAux,1,nY-7) + cTrb + Substr(cAux,nY)
                    EndIf
                    cTrb :=''
                    Loop
                EndIf
                cTrb += Substr(cAux,nY,1)
            next
            cRet += 'cQuery += " '+(cAux)+' " '+CRLF
        EndIf
    next
Return cRet

/*/{Protheus.doc} ADVPL2SQL
(long_description)
@author Alex Sandro
@since 05/09/2014
@version 1.0
@param cTrb, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function ADVPL2SQL(cTrb)
    Local aQry := StrTokArr(QryTrim(cTrb),CRLF)
    Local nX := 0
    Local xAux :=""
    Local cBrkLine:=""
    Local cRet :=""
    Local bErroA

    bErroA	:= ErrorBlock( { |oErro| ChkErr( oErro , .T. ) } )
    Begin Sequence

        for nX:= 1 to Len(aQry)
            If !empty(aQry[nX])
                aQry[nX]:= Alltrim(aQry[nX])
                If Right(aQry[nX],1)== ';'
                    cBrkLine += SubStr(aQry[nX],1,len(aQry[nX])-1)
                    loop
                EndIf
                xAux:= &(cBrkLine+aQry[nX])
                cBrkLine:=''
                If Valtype(xAux)=='C'
                    cRet:= xAux
                EndIf
            EndIf
        next

    End Sequence
    ErrorBlock( bErroA )

    If ! Empty(cErroA)
        If ":=" $ cErroA
            If  ! cErroA $ cTrb
                cTrb := cErroA + cTrb
            Endif
            cRet := ""
        Else
            cRet := cErroA
        EndIf
        cErroA :=""
    EndIf

    cRet:=Format(cRet)

Return cRet

Static Function QryTrim(cQrySup2)
    Local cA := ""
    Local nx := 0
    Local aQry := StrTokArr(cQrySup2, CRLF)

    For nx:=1 to len(aQry)
        cLinha :=aQry[nx]
        cLinha := StrTran(cLinha, chr(9), "")
        cLinha := StrTran(cLinha, "+CRLF", "")
        cLinha := StrTran(cLinha, "+ CRLF", "")
        cLinha := Alltrim(cLinha)
        cA += cLinha + CRLF
    Next
    cQrySup2 := cA

Return cA



Static Function LeDirect(oObjList,oGetInfo,cInfoPath,lClick)

    Local aRetList := {{"0","..","","",""}}
    Local aArqInfo := {}
    Local cFile := ''

    DEFAULT lClick := .F.

    cInfoPath := AllTrim(cInfoPath)

    If lClick
        If oObjList:aArray[oObjList:nAt][1] == "0"
            cInfoPath := Substr(cInfoPath,1,RAT("\",Substr(cInfoPath,1,Len(cInfoPath)-1)))
        ElseIf oObjList:aArray[oObjList:nAt][1] == "1"
            cInfoPath := cInfoPath+AllTrim(oObjList:aArray[oObjList:nAt][2])+"\"
        Else
            If (':'$cInfoPath)
                cFile := cInfoPath+AllTrim(oObjList:aArray[oObjList:nAt][2])
            Else
                cPathDes := GetTempPath()
                If CPYS2T(cInfoPath+oObjList:aArray[oObjList:nAt][2],cPathDes,.T.)
                    cFile := cPathDes+oObjList:aArray[oObjList:nAt][2]
                Else
                    MsgAlert("Erro ao copiar arquivo.")
                EndIf
            EndIf

            If !empty(cFile)
                ShellExecute('open','cmd.exe','/k '+cFile , "", 0)
            EndIf

            Return
        EndIf
    EndIf

    aArqInfo := Directory(cInfoPath + cMaskArq, "D")

    If Len(aArqInfo) > 0
        AEval(aArqInfo,{|x,y| If(Left(AllTrim(x[1]),1)!=".",AAdd(aRetList,{Iif("D"$x[5],"1","2"),x[1],PADR(Ceiling(x[2]/1024),12)+' KB',x[3],x[4]}),) })
        ASort(aRetList,,,{|x,y| x[1]+x[2] < y[1]+y[2] })
    EndIf

    oObjList:SetArray(aRetList)
    oObjList:bLine := { || {Iif(aRetList[oObjList:nAt][1] == "2",oFilBMP,oFolBMP),aRetList[oObjList:nAt][2],aRetList[oObjList:nAt][3],aRetList[oObjList:nAt][4],aRetList[oObjList:nAt][5]}}

    oObjList:nAt := 1
    oObjList:Refresh()
    oGetInfo:Refresh()

Return


Static Function OpenBtn(cAtual,cOnde)
    Local cRetDir := ""
    If cOnde == "T"
        cRetDir := cGetFile("Todos Arquivos|*.*|","Escolha o caminho dos arquivos.",0,cAtual,,GETF_RETDIRECTORY+GETF_LOCALHARD+GETF_LOCALFLOPPY+GETF_NETWORKDRIVE)
    ElseIf cOnde == "S"
        cRetDir := cGetFile("Todos Arquivos|*.*|","Escolha o caminho dos arquivos.",0,cAtual,,GETF_RETDIRECTORY+GETF_ONLYSERVER)
    EndIf
    cRetDir := Iif(Empty(cRetDir),cAtual,cRetDir)
Return cRetDir


Static Function FCopia(cPathOri,cPathDes,oObjList,lMultCpy)
    Local aMultCopy := {}
    Private lAbortPrint := .F.

    DEFAULT lMultCpy := .F.

    If lMultCpy
        AEval(oObjList:aArray,{|x,y| If(x[1] == "2",AAdd(aMultCopy,AllTrim(x[2])),) })
        ProcRegua(Len(aMultCopy))
        If ":" $ cPathOri
            AEval(aMultCopy,{|x,y| If(!lAbortPrint, (CPYT2S(cPathOri+x,cPathDes,.T.), IncProc("Copiando "+Transform(y*100/Len(aMultCopy),"@E 99")+"% - "+x) ),) })
        Else
            AEval(aMultCopy,{|x,y| If(!lAbortPrint, (CPYS2T(cPathOri+x,cPathDes,.T.), IncProc("Copiando "+Transform(y*100/Len(aMultCopy),"@E 99")+"% - "+x) ),) })
        EndIf
    ElseIf oObjList:aArray[oObjList:nAt][1] == "2"
        If ":" $ cPathOri
            If !CPYT2S(cPathOri+oObjList:aArray[oObjList:nAt][2],cPathDes,.T.)
                MsgAlert("Erro ao copiar arquivo.")
            EndIf
        Else
            If !CPYS2T(cPathOri+oObjList:aArray[oObjList:nAt][2],cPathDes,.T.)
                MsgAlert("Erro ao copiar arquivo.")
            EndIf
        EndIf
    Else
        MsgAlert("Não copia pastas.")
    EndIf
Return

Static Function FApaga(cPathOri,oObjList,lEraseMult)

    Local aMultErase := {}
    Local cEraseFile := AllTrim(oObjList:aArray[oObjList:nAt][2])

    Private lAbortPrint := .F.

    DEFAULT lEraseMult := .F.

    If lEraseMult
        AEval(oObjList:aArray,{|x,y| If(x[1] == "2",AAdd(aMultErase,AllTrim(x[2])),) })
        ProcRegua(Len(aMultErase))
        If MsgNoYes("Confirma a exclusao de "+AllTrim(Str(Len(aMultErase)))+" arquivos?")
            AEval(aMultErase,{|x,y| If(!lAbortPrint, (FErase(AllTrim(cPathOri)+x), IncProc("Apagando "+Transform(y*100/Len(aMultErase),"@E 99")+"% - "+x) ),) })
        EndIf
    ElseIf oObjList:aArray[oObjList:nAt][1] == "2"
        If MsgNoYes("Apagar o arquivo ["+cEraseFile+"]?")
            FErase(AllTrim(cPathOri)+cEraseFile)
        EndIf
    Else
        MsgAlert("Não apaga pastas.")
    EndIf

Return


Static Function MaskDir

    Local oDlMask,oGetMask

    cMaskArq := Padr(cMaskArq,60)

    DEFINE MSDIALOG oDlMask TITLE "Informe a mascara de arquivos." FROM 0,0 TO 30,230 PIXEL
    @ 02,02 MSGET oGetMask VAR cMaskArq PICTURE "@!" PIXEL SIZE 70,009 VALID Len(AllTrim(cMaskArq)) >= 3 .And. "." $ cMaskArq
    @ 02,75 BUTTON "Ok" SIZE 037,012 PIXEL OF oDlMask Action oDlMask:End()
    ACTIVATE MSDIALOG oDlMask CENTERED VALID Len(AllTrim(cMaskArq)) >= 3 .And. "." $ cMaskArq

    cMaskArq := AllTrim(cMaskArq)

Return

Static Function DicTst(cAliasDic, oPnlDicI)
    Local nX := 0
    Local uValue
    Local cValue
    Local aAreaSx3 := SX3->(GetArea("SX3"))
    Local cResult:= ""
    Local aEstru
    Local cAux:=""
    Local nRecSx3 := SX3->(Recno())

    SX3->(dbSetOrder(1))
    If ! SX3->(DbSeek(cAliasDic))
        RestArea(aAreaSx3)
        SX3->(DbGoto(nRecSx3))
        Return
    EndIf

    SX3->(dbSetOrder(2))
    aEstru := (cAliasDic)->(dbStruct())

    cResult += " *** Comparação de estrutura do banco com SX3 ***" + CRLF

    For nx:=1 to len(aEstru)
        cResult += "Campo: " + aEstru[nx,1]
        cAux := ""
        If ! SX3->(DbSeek(aEstru[nx, 1]))
            cResult +=  CRLF + "    Não cadastrado SX3 com Tipo [" + aEstru[nx, 2] + "] Tamanho ["+ Str(aEstru[nx, 3]) +"] Decimal ["+ Str(aEstru[nx, 4]) +"] " + CRLF
            Loop
        EndIf
        If ! SX3->X3_TIPO == aEstru[nx, 2]
            cAux += CRLF + "    Tipo diferente: DB [" + aEstru[nx, 2] + "] SX3 [" +SX3->X3_TIPO + "]"
        Endif
        If ! SX3->X3_TAMANHO == aEstru[nx, 3]
            cAux += CRLF + "    Tamanho diferente: DB [" + Str(aEstru[nx, 3]) + "] SX3 [" + Str(SX3->X3_TAMANHO, 3) + "]"
        Endif
        If ! SX3->X3_DECIMAL == aEstru[nx, 4]
            cAux += CRLF + "    Decimal diferente:  DB [" + Str(aEstru[nx, 4]) + "] SX3 [" + Str(SX3->X3_DECIMAL, 3) + "]"
        Endif
        If Empty(cAux)
            cResult += " OK" + CRLF
        Else
            cResult += cAux + CRLF
        EndIf
    Next

    cResult += "*** Verificando campos não criados no DB ***" + CRLF
    cAux := ""
    SX3->(dbSetOrder(1))
    SX3->(DbSeek(cAliasDic))
    While   SX3->(! Eof() .and. X3_ARQUIVO == cAliasDic)
        If SX3->X3_CONTEXT == 'V'
            SX3->(dbSkip())
            Loop
        EndIf

        If Ascan(aEstru, {|x| Alltrim(x[1]) == Alltrim(SX3->X3_CAMPO) }) > 0
            SX3->(dbSkip())
            Loop
        EndIf

        cAux += "Campo " + Alltrim(SX3->X3_CAMPO) + ":"+ CRLF
        For nX:= 1 to SX3->(fcount())
            SX3->(uValue:= &(field(nx)))
            If ValType(uValue) != 'C'
                cValue:= str(uValue)
            Else
                cValue := uValue
            EndIf
            cAux += SX3->(field(nx)) + " = " + cValue + CRLF
        Next

        SX3->(DbSkip())
    EndDo

    If Empty(cAux)
        cResult += "  OK - Todos os campos do SX3 estão criados no DB." + CRLF
    Else
        cResult += "Relação de inexistencia:" + CRLF
        cResult += cAux + CRLF
    EndIf
    cResult += CRLF + CRLF + CRLF

    AutoGrLog("")
    FErase(NomeAutoLog())
    AutoGrLog(cResult)
    MostraErro()

    RestArea(aAreaSx3)
    SX3->(DbGoto(nRecSx3))

Return

Static Function Estru(cAliasDic, oPnlDicI, np)
    Local nCount
    Local aDados := {}
    Local aFields:= { 'CAMPO               ','TIPO','TAMANHO','DECIMAL'}

    If ValType(aDicBrw[np])=='O'
        aDicBrw[np]:DeActivate(.T.)
    EndIf

    aDicBrw[np] := FWBrowse():New(oPnlDicI)
    aDicBrw[np]:SetDataArray(.T.)
    aDicBrw[np]:SetDescription("Estrutura")
    aDicBrw[np]:SetUpdateBrowse({||.T.})
    aDicBrw[np]:SetEditCell(.T.,{||.F.})
    aDicBrw[np]:SetSeek()
    aDicBrw[np]:SetUseFilter()
    aDicBrw[np]:SetDBFFilter()

    aColunas := {}
    for nCount:= 1 to Len(aFields)
        oCol := FWBrwColumn():New()
        oCol:SetTitle(aFields[nCount])
        oCol:SetData(&("{|x|x:oData:aArray[x:At()]["+Str(nCount)+"]}"))
        aAdd(aColunas,oCol)
    next

    aDados := (cAliasDic)->(dbStruct())

    aDicBrw[np]:SetColumns(aColunas)
    aDicBrw[np]:SetArray(aDados)
    aDicBrw[np]:Activate()

Return



Static Function AtuSX3toDB(cAliasSX, oPnlDicI, np)
    Local cMsg:=""
    Local cAliasTst

    If ! MsgYesNo("Confirma o sincronismo entre o SX3 e o banco?")
        return
    EndIf

    cAliasTst := aAliasDic[np]

    If Select(cAliasTst) > 0
        (cAliasTst)->(DbCloseArea())
    EndIf

    If Select(cAliasSX) > 0
        (cAliasSX)->(dbCloseArea())
    EndIf

    cMsg := StartJob("u_TIDEVX31",GetEnvServer(),.T.,SM0->M0_CODIGO,Alltrim(SM0->M0_CODFIL), cAliasSX)

    AutoGrLog("")
    FErase(NomeAutoLog())
    AutoGrLog(cMsg)
    MostraErro()

Return



User Function TIDEVX31(cEmp, cFil, cAlias)
    Local cMsg:= ""

    RpcSetType(3)
    RpcSetEnv(cEmp, cFil,,,,,)

    //PTInternal(1, "Atualizando tabela:" + cAlias +  " Empresa:" + cEmp)

    __SetX31Mode(.F.)

    X31UpdTable(cAlias)

    If __GetX31Error()
        cMsg :=__GetX31Trace()
    Else
        cMsg:= "Atualização do alias ["+cAlias+"] realizada com sucesso! "
    EndIf

Return cMsg



Static Function Tools(cQry,oOwner, np)

    Local nX := 0
    Local oMenu
    Local oIte1
    Local oIte4
    LOcal oIte4_1
    Local cAux:= ''
    Local bBlock:={||}

    oMenu := tMenu():new(0, 0, 0, 0, .T., , oOwner)

    oMenu:Add(oIte4 := tMenuItem():new(oMenu, "Historico"		, , 		, , {|| }					, , , , , , , , , .T.))

    oIte4:Add(oIte4_1 := tMenuItem():new(oMenu, "Limpar Histórico", , , , {||  If(MsgYesNo("Confirma a limpeza do historico?"), (aQryHst[np] := {}, SaveJson()), .t.) }, , , , , , , , , .T.))

    For nX := Len(aQryHst[np]) To 1 Step -1
        cAux := cValToChar(nX)+ ". " + Left( Alltrim(aQryHst[np, nX]), 120)
        bBlock:=&('{|| cQry:= aQryHst[' + str(np) + ',' + str(nX) + ']}')
        oIte4:Add(tMenuItem():new(oIte1, cAux, , , , bBlock, , , , , , , , , .T.))
    Next

    oMenu:Activate(NIL, 21, oOwner)

Return

Static Function Tools2(cCMD, oOwner)

    Local nX := 0
    Local oMenu
    Local oIte1
    Local oIte4
    Local oIte4_1
    Local cAux:= ''
    Local bBlock:={||}

    If Empty(aCmdHst)
        aadd(aCmdHst, "GetUserInfoArray()")
        aadd(aCmdHst, "cProg:= 'TIDEV.PRW', Alert(VarInfo('Info',GetAPOInfo(cProg),,.F.))")
    EndIf

    oMenu := tMenu():new(0, 0, 0, 0, .T., , oOwner)

    oMenu:Add(oIte4 := tMenuItem():new(oMenu, "Historico"		, , 		, , {|| }					, , , , , , , , , .T.))

    oIte4:Add(oIte4_1 := tMenuItem():new(oMenu, "Limpar Histórico", , , , {|| If(MsgYesNo("Confirma a limpeza do historico?"), (aCmdHst := {}, SaveJson()), .t.) }, , , , , , , , , .T.))

    For nX := Len(aCmdHst) To 1 Step -1
        cAux := cValToChar(nX)+ ". " + Left( Alltrim (aCmdHst[nX]), 120)
        bBlock:=&('{|| cCMD:= aCmdHst[' + str(nX) + ']}')
        oIte4:Add(tMenuItem():new(oIte1, cAux, , , , bBlock, , , , , , , , , .T.))
    Next

    oMenu:Activate(NIL, 21, oOwner)

Return

Static Function Tools3(cCMD, oOwner)

    Local nX := 0
    Local oMenu
    Local oIte1
    Local oIte4
    Local oIte4_1
    Local cAux:= ''
    Local bBlock:={||}

    oMenu := tMenu():new(0, 0, 0, 0, .T., , oOwner)

    oMenu:Add(oIte4 := tMenuItem():new(oMenu, "Historico"		, , 		, , {|| }					, , , , , , , , , .T.))

    oIte4:Add(oIte4_1 := tMenuItem():new(oMenu, "Limpar Histórico", , , , {|| If(MsgYesNo("Confirma a limpeza do historico?"), (aCmdHst := {}, SaveJson()), .t.) }, , , , , , , , , .T.))

    For nX := Len(aB64Hst) To 1 Step -1
        cAux := cValToChar(nX)+ ". " + Left( Alltrim (aB64Hst[nX]), 120)
        bBlock:=&('{|| cCMD:= aB64Hst[' + str(nX) + ']}')
        oIte4:Add(tMenuItem():new(oIte1, cAux, , , , bBlock, , , , , , , , , .T.))
    Next

    oMenu:Activate(NIL, 21, oOwner)

Return

Static Function FileQry(lOpen,cTrb)
    Local cFile := ''

    If lOpen
        //cFile := cGetFile("Todos Arquivos|*.*|", "Abrir Query:", 0, "C:\" , .T., GETF_LOCALHARD + GETF_LOCALFLOPPY + GETF_NETWORKDRIVE)
        cFile := cGetFile( "Arquivos query (*.query) |*.query|" , "Selecione o arquivo", 1, "C:\", .T., GETF_LOCALHARD + GETF_LOCALFLOPPY + GETF_NETWORKDRIVE )
        If ! empty(cFile)

            cTrb:= MemoRead(cFile)
        EndIf
    Else
        cFile := cGetFile("Arquivos query (*.query) |*.query|","Informe o arquivo", 0, "C:\", .F., GETF_LOCALHARD + GETF_LOCALFLOPPY + GETF_NETWORKDRIVE)
        If ! empty(cFile)
            If Right(Upper(cFile), 6) <> ".QUERY"
                cFile += ".query"
            EndIf
            MemoWrit(cFile, cTrb)
        EndIf
    EndIf


Return

Static Function NewPanel(nTop, nLeft, nBottom, nRight, oOwner)
    Local oPanel

    oPanel := TPanelCss():New(,,,oOwner)
    oPanel:SetCoors(TRect():New(nTop, nLeft, nBottom, nRight))

Return  oPanel

Static Function NewMemo(cText,oOwner)
    Local oMemo
    Local oFont
    Default cText := ''
    
    oFont:= TFont():New("Consolas",, 20,, .F.,,,,, .F. )
    oMemo := tMultiget():new(,, bSETGET(cText), oOwner)
    oMemo:Align := CONTROL_ALIGN_ALLCLIENT
    oMemo:oFont:=oFont

Return oMemo

Static Function InitEmp(aEmpExQr,oTMsgItem, lAuto, oDlg, oFol )
    Local lRet:= .F.

    Local __cEmp
    Local __cFil

    DEFAULT lAuto := .F.

    Static cUsrFs := Space(25)//"Administrador"
    Static cPswFS := Space(40)

    lRet := lAuto

    If Empty(aEmpExQr)
        OpenSm0()
        dbSelectArea("SM0")

        If !SelEmp(@__cEmp, @__cFil)
            oDlg:End()
            Return .F.
        Endif

        If oFol <> NIL
            oFol:SetOption(1)
        EndIf
        RpcClearEnv()

        RpcSetType(3)
        MsgRun("Montando Ambiente. Empresa [" + __cEmp + "] Filial [" + __cFil +"].", "Aguarde...", {||lRet := RpcSetEnv( __cEmp, __cFil,,,,,) } )
        If !lRet
            MsgAlert("Não foi possível montar o ambiente selecionado. " )
            oDlg:End()
            Return .F.
        EndIf
        __cInterNet := Nil
        //PTInternal(1, "### TOTVS TI DEVELOPER ###" )
    EndIf

    If ValType(oTMsgItem)=='O'
        oTMsgItem:SetText("Empresa/Filial: [" + __cEmp + "/" + __cFil + "] ")
    EndIf

Return lRet



Static Function SelEmp(__cEmp, __cFil)
    Local oDlgLogin
    Local oCbxEmp
    Local oFont
    Local cEmpAtu			:= ""
    Local lOk				:= .F.
    Local aCbxEmp			:= {}

    oFont := TFont():New('Arial',, -11, .T., .T.)

    SM0->(DbGotop())
    While ! SM0->(Eof())
        Aadd(aCbxEmp,SM0->M0_CODIGO+'/'+SM0->M0_CODFIL+' - '+Alltrim(SM0->M0_NOME)+' / '+SM0->M0_FILIAL)
        SM0->(DbSkip())
    EndDo

    DEFINE MSDIALOG oDlgLogin FROM  0,0 TO 210,380  Pixel TITLE "Login "
    oDlgLogin:lEscClose := .F.
    @ 010,005 Say "Selecione a Empresa:" PIXEL of oDlgLogin  FONT oFont //
    @ 018,005 MSCOMBOBOX oCbxEmp VAR cEmpAtu ITEMS aCbxEmp SIZE 180,10 OF oDlgLogin PIXEL

    TButton():New( 085,100,"&Ok"       , oDlgLogin, {|| lOk := .T.  ,oDlgLogin:End() }, 38, 14,,, .F., .t., .F.,, .F.,,, .F. )
    TButton():New( 085,140,"&Cancelar" , oDlgLogin, {|| lOk := .F. , oDlgLogin:End() }, 38, 14,,, .F., .t., .F.,, .F.,,, .F. )
    ACTIVATE MSDIALOG oDlgLogin CENTERED

    If lOk
        npB     := at("/", cEmpAtu)
        __cEmp  := Left(cEmpAtu, npB - 1)
        cEmpAtu := Subs(cEmpAtu, npB + 1)
        npT     := at("-", cEmpAtu)
        __cFil  := Left(cEmpAtu, npT - 2)
    EndIf

Return lOk



Static Function FAtualiz(cPesq,oBox,nCol)

    Local aDados := oBox:aArray
    Local nPos   := 0

    cPesq := Alltrim(cPesq)

    If oBox:nAt < Len(aDados) .And. ( nPos := AScan(aDados,{|x| cPesq $ Alltrim(x[nCol]) },oBox:nAt+1) ) > 0
        oBox:nAt := nPos
    ElseIf ( nPos := AScan(aDados,{|x| cPesq $ Alltrim(x[nCol]) }) ) > 0
        oBox:nAt := nPos
    Else
        oBox:nAt := Len(aDados)
    EndIf

    oBox:Refresh()
    oBox:SetFocus()

Return



Static Function Format(cFormat)
    Local cQry := ""
    Local cAux := ""
    Local cWord:= ""
    Local aQry := {}
    Local nX   := 0
    Local cLinha:= ''
    Local cByte:= ""
    Local nSelect:= 0

    cFormat := ChangeQuery(cFormat)

    aQry := StrTokArr(cFormat, CRLF)
    For nx := 1 to len(aQry)
        cLinha := aQry[nx]
        cLinha := StrTran(cLinha, CHR(9) , " ")
        cLinha := Alltrim(cLinha)
        cLinha := Upper(cLinha)
        cQry += cLinha+" "
    Next

    cAux := ""
    aQry := {}
    For nX:= 1 to len(cQry)
        cByte := Subs(cQry,nX,1)
        cByte2:= Subs(cQry,nX+1,1)
        cByte3:= Subs(cQry,nX+2,1)

        If Upper(cByte) $ "_ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
            cWord += cByte
        Else
            If len(cword) > 0 .and.  ;
                    (" " + cWord + "#"        $ " SELECT# FROM# WHERE#" .or.;
                    " " + cWord + cByte + "#"  $ " AND # OR # NOT # INNER # LEFT # RIHGT #"   .or.;
                    " " + cWord + cByte + cByte2 + cByte3 + "#" $ " ORDER BY#" )

                cLinha:= Left(cAux, len(cAux)-len(cWord))
                If ! Empty(cLinha)
                    aadd(aQry, cLinha)
                EndIf

                cAux := cWord

            EndIf
            cWord:= ""
        EndIf
        cAux += cByte
        If nX==len(cQry) .and. ! Empty(cAux)
            cLinha:= cAux
            If ! Empty(cLinha)
                aadd(aQry, cLinha)
            EndIf
        EndIf
    Next

    nSelect := -1
    For nx := 1 to len(aQry)
        cLinha := aQry[nx]
        If "SELECT " $ cLinha
            nSelect++
        EndIf
        cLinha := Alltrim(cLinha) + " "
        cLinha := Upper(cLinha)

        cLinha := If(Left(cLinha, 4) == "AND "," " + cLinha, cLinha)
        cLinha := If(Left(cLinha, 3) == "OR " ," " + cLinha, cLinha)
        cLinha := If(Left(cLinha, 4) == "NOT "," " + cLinha, cLinha)

        //cLInha := StrTran(cLinha, "SELECT " ,  "SELECT ")
        cLinha := StrTran(cLinha, "FROM "   ,  "FROM   ")
        cLinha := StrTran(cLinha, "WHERE "  ,  "WHERE ")
        cLinha := StrTran(cLinha, " AND "   , "       AND ")
        cLinha := StrTran(cLinha, " OR "    , "        OR ")
        cLinha := StrTran(cLinha, " NOT "   , "       NOT ")
        cLinha := Repl(" ", Max(nSelect * 7, 0) ) + cLinha
        aQry[nx] := cLinha
        If "WHERE " $ cLinha
            nSelect--
        EndIf
    Next

    cQry := ""
    For nx:=1 to len(aQry)
        cQry += aQry[nx] + CRLF
    Next

Return cQry

Static Function SaveJson()
    Local cFile := GetTempPath() + "tidev.json"
    Local cConteudo := ""

    cConteudo := FwJsonSerialize({aQryHst, aCmdHst })
    MemoWrit(cFile, cConteudo )

Return

Static Function LoadJson()
    Local cFile := GetTempPath() + "tidev.json"
    Local cConteudo := ""
    Local aAux := {}

    cConteudo := MemoRead(cFile)
    If ! Empty(cConteudo)
        FWJsonDeserialize(cConteudo, @aAux)
        aQryHst := aClone(aAux[1])
        aCmdHst := aClone(aAux[2])
    EndIf

Return

Static Function FolderB64(oFol7, oSize)
    Local nLin:= 02
    Local nCol:= 02
    Local nM := 3
    Local nT := oSize:GetDimension("PANEL", "LININI")
    Local nL := oSize:GetDimension("PANEL", "COLINI")
    Local nB := oSize:GetDimension("PANEL", "LINEND")
    Local nR := oSize:GetDimension("PANEL", "COLEND")
    Local lMultiline := .F.
    Local nWm := (nR - nL)/2
    Local nHm := (nB - nT)/2
    Local oBut
    Local oBut2
    Local cPnlCmdSup:=""
    Local oPnlCmdSup
    Local oPnlCmdI
    Local oTime
    Local cTime		:= "00:00:00 "
    Local oTxtCmdSup
    Local oOpB64 := {}
    Local nOpB64 := 2

    @ nLin, nCol BUTTON oBut PROMPT '&Executar' SIZE 045,010 ACTION ExecB64(cPnlCmdSup, oPnlCmdI, oTime, lMultiline, nOpB64) OF oFol7 PIXEL; oBut:nClrText :=0
    @ nLin, nCol+=50 BUTTON oBut2 PROMPT 'Histórico'     SIZE 045,010 ACTION {|| Tools3(@cPnlCmdSup, oBut2),oTxtCmdSup:Refresh() }   OF oFol7 PIXEL ; oBut2:nClrText := 0
    @ nLin, nCol+=50 CHECKBOX oCheck VAR lMultiline    PROMPT 'Linha-a-linha'	   SIZE 060,010 OF oFol7 PIXEL
    @ nLin+1, nCol+=70 RADIO oOpB64 VAR nOpB64 ITEMS 'Encode Base64', 'Decode Base64' OF oFol7 ON CHANGE { || .T. } SIZE 110,10 PIXEL
    @ nLin+1, nWm - 100 SAY "Run Time: "   SIZE 030,010 OF oFol7 PIXEL
    @ nLin+1, nWm - 75 SAY oTime VAR cTime SIZE 070,010 OF oFol7 PIXEL

    oOpB64:lHoriz := .T.

    oPnlCmdSup := NewPanel(nT + nM, nL + nM, nHm - nM, nR - nM, oFol7)
    oTxtCmdSup := NewMemo(@cPnlCmdSup, oPnlCmdSup)

    oPnlCmdI := NewPanel(nHm + nM, nL + nM, nB - nM- 60, nR - nM, oFol7)

Return

/*{Protheus.doc} ExecMacro
@author Izac
@since 18/06/2014
@version 1.0
@param cTrb, character
@return cRet, character
*/
Static Function ExecB64(cTrb, oPnlCmdI, oTime, lMultiline, nOpB64)
    Local cRet:=""
    Local cRetM:= ""
    Local cPnlCmdI := ""
    Local oMemErr
    Local nSec1 := 0
    Local nSec2 := 0
    Local nPos
    Local aDataAux := {}
    Local aDataRet := {}
    Local nForCpo  := 0

    Default nOpB64 := 2

    nSec1 := Seconds()

    If lMultiline
        aDataAux := Strtokarr2( cTrb, CRLF, .T.)

        For nForCpo := 1 To Len(aDataAux)

            If nOpB64 == 1
                aAdd(aDataRet,Encode64( aDataAux[nForCpo] ) )
            Else
                aAdd(aDataRet,Decode64( aDataAux[nForCpo] ) )
            EndIf

        Next nForCpo

        For nForCpo := 1 To Len(aDataRet)
            cRetM += aDataRet[nForCpo] + CRLF
        Next nForCpo

    Else

        If nOpB64 == 1
            cRetM += Encode64( cTrb )
        Else
            cRetM += Decode64( cTrb )
        EndIf

    EndIf

    nPos := aScan(aB64Hst, {|x| x == cTrb})
    If Empty(nPos)
        aAdd(aB64Hst, cTrb)
    Else
        aDel(aB64Hst,nPos)
        aB64Hst[len(aB64Hst)] := cTrb
    EndIf
    SaveJson()

    cPnlCmdI := cRetM

    nSec2 := Seconds()
    oTime:SetText( APSec2Time(nSec2-nSec1) + " (" + Alltrim(Str(nSec2-nSec1)) + " segs.)" )

    @ 0,0 GET oMemErr VAR cPnlCmdI OF oPnlCmdI MEMO size 0,0
    oMemErr:Align := CONTROL_ALIGN_ALLCLIENT

Return cRet


Static Function FolderSX6(oFol, oSize)
    Local oBut
    LOcal oPanelM1
    Local oPnlInfI
    Local cGrupo   := Space(3)
    Local nSize    := 0
    Local nSizeMin := 0
    Local nSizeMax := 0
    Local aSX3 := {}

    oPanelM1 := TPanelCss():New(,,,oFol)
    oPanelM1 :SetCoors(TRect():New( 0,0, 30, 30))
    oPanelM1 :Align := CONTROL_ALIGN_TOP


    @ 004, 002 SAY "Grupo:" of oPanelM1 SIZE 030, 09 PIXEL
    @ 003, 025 GET cGrupo   of oPanelM1  Pict  "999" SIZE 030, 08 PIXEL Valid If(VldGrupo(cGrupo, @nSize, @nSizeMin, @nSizeMax), PesqSX3(cGrupo, oPnlInfI, aSX3, nSize), .t.)

    @ 004, 062 SAY "Size:" of oPanelM1 SIZE 030, 09 PIXEL
    @ 003, 085 GET nSize   of oPanelM1  Pict  "999" SIZE 030, 08 PIXEL Valid If(VldSize(cGrupo, nSize), PesqSX3(cGrupo, oPnlInfI, aSX3, nSize), .t.)

    @ 004, 122 SAY "Size Min:" of oPanelM1 SIZE 030, 09 PIXEL
    @ 003, 145 GET nSizeMin    of oPanelM1  Pict  "999" SIZE 030, 08 PIXEL when .F.

    @ 004, 182 SAY "Size Max:" of oPanelM1 SIZE 030, 09 PIXEL
    @ 003, 205 GET nSizeMax   of oPanelM1  Pict  "999" SIZE 030, 08 PIXEL when .F.

    @ 003, 240 BUTTON  oBut PROMPT 'Corrigir SX3' SIZE 045,010 ACTION If(AlteraSX3(cGrupo, nSize, aSX3), PesqSX3(cGrupo, oPnlInfI, aSX3, nSize), .t.) OF oPanelM1 PIXEL ; oBut:nClrText :=0

    oPnlInfI:= TPanelCss():New(,,,oFol)
    oPnlInfI:Align :=CONTROL_ALIGN_ALLCLIENT


Return

Static Function VldGrupo(cGrupo, nSize, nSizeMin, nSizeMax)

    cGrupo := StrZero(Val(cGrupo), 3)

    SXG->(DbSetOrder(1))
    If ! SXG->(DbSeek(cGrupo))
        Alert("Grupo não cadastrado no SXG!")        
        Return .F. 
    EndIf 
    nSize     := SXG->XG_SIZE
    nSizeMin  := SXG->XG_SIZEMIN
    nSizeMax  := SXG->XG_SIZEMAX

Return .t.


Static Function VldSize(cGrupo, nSize)

    cGrupo := StrZero(Val(cGrupo), 3)

    SXG->(DbSetOrder(1))
    If ! SXG->(DbSeek(cGrupo))
        Alert("Grupo não cadastrado no SXG!")        
        Return .F. 
    EndIf 
    If SXG->XG_SIZE <> nSize
        If ! MsgNoYes("Confirma o ajuste do size do grupo de " + Alltrim(Str(SXG->XG_SIZE)) + " para " + Alltrim(Str(nSize)) )
            Return 
        EndIf 
        SXG->(RecLock("SXG", .F.))
        SXG->XG_SIZE := nSize 
        SXG->(MsUnLock())
        Return .t.
    EndIf 

Return .f.


Static Function PesqSX3(cGrupo, oPnlInfI, aSX3, nSize)
    Local nCount
    Local aFields:= { 'X2_ARQUIVO','X3_CAMPO','X3_TAMANHO','X3_DECIMAL','X3_GRPSXG','Existe Arq','Qtde Registros', "Analise", ""}

    If empty(cGrupo)
        Return
    EndIf

    If empty(cFilAnt) .or. empty(cEmpAnt)
        MsgInfo("Ambiente Não Inicializado")
        Return
    EndIf

    If Type('oInfBrw')=='O'
        oInfBrw:DeActivate(.T.)
    EndIf
    oInfBrw := FWBrowse():New(oPnlInfI)
    oInfBrw:SetDataArray(.T.)
    oInfBrw:SetDescription("SX3")
    oInfBrw:SetUpdateBrowse({||.T.})
    oInfBrw:SetEditCell(.T.,{||.F.})
    //oInfBrw:SetDoubleClick({|o|BuscaPar(o, oPnlInfI2 )})
    oInfBrw:SetSeek()
    oInfBrw:SetUseFilter()
    oInfBrw:SetDBFFilter()

    aColunas := {}
    for nCount:= 1 to Len(aFields)
        oCol := FWBrwColumn():New()
        oCol:SetTitle(aFields[nCount])
        oCol:SetData(&("{|x|x:oData:aArray[x:At()]["+Str(nCount)+"]}"))
        aAdd(aColunas,oCol)
    next

    MsgRun("Buscando campos relacionados ao grupo.","Aguarde",{|| aSX3 := CarregaSX3(cGrupo, nSize)})
    oInfBrw:SetColumns(aColunas)
    oInfBrw:SetArray(aSX3)
    oInfBrw:Activate()
Return

Static Function CarregaSX3(cGrupo, nSize)
    Local aSX3 := {}
    Local nTotReg := 0
    Local cExiste := "Não"
    Local cAlias  := ""
    Local cFiltro := ""
    Local nRec    := SX3->(Recno())

    cGrupo := StrZero(Val(cGrupo), 3)

    cFiltro := "X3_GRPSXG = '" + cGrupo + "'"

    SX3->(DbSetFilter({|| &cFiltro} ,cFiltro))

    SX3->(DbGotop())
    While SX3->(! Eof() )
        cAnalise := Space(30)
        If nSize <> SX3->X3_TAMANHO
            cAnalise := "DIFERENTE"
        EndIf

        SX2->(DbSeek(SX3->X3_ARQUIVO))

        cArquivo  := Alltrim(SX2->X2_ARQUIVO)
        nTotReg   := 0
        cAlias    := SX3->X3_ARQUIVO

        If MsFile(cArquivo,,"TOPCONN")

            If Select(cAlias + "X") > 0
                (cAlias + "X")->(DbCloseArea())
            EndIf

            dbUseArea( .T., "TOPCONN", cArquivo, cAlias + "X", .T., .F.)
            If Select(cAlias + "X") > 0
                nTotReg  := (cAlias + "X")->(LastRec())
                (cAlias + "X")->(DbCloseArea())
            EndIf
            cExiste := "Sim"
        Else 
            cExiste := "Não"
        EndIf

        aadd(aSX3,  {SX2->X2_ARQUIVO, SX3->X3_CAMPO, SX3->X3_TAMANHO, SX3->X3_DECIMAL, SX3->X3_GRPSXG, cExiste, nTotReg, cAnalise, "", SX3->(Recno()) })
        SX3->(DbSkip())
    End
    SX3->(DbClearFilter())
    SX3->(DbGoto(nRec))

Return aSX3


Static Function AlteraSX3(cGrupo, nSize, aSX3)
    Local lAtu     := .F.
    Local lVarias  := .F.

    If ! MsgNoYes("Confirma a alteração do tamanho dos campos diferentes do size para tamanho " + Alltrim(Str(nSize)) + "?")
        Return lAtu
    EndIf 

    If MsgYesNo("Utiliza varias threads para os ajustes nas tabelas?")
        lVarias  := .T.
    EndIf 

    Processa({|| lAtu := ProcAltSX3(cGrupo, nSize, aSX3, lVarias) }, "Atualizando SX3","Atualizando",.T.)

Return lAtu

Static Function ProcAltSX3(cGrupo, nSize, aSX3, lVarias)
    Local nx := 0
    Local nRec     := SX3->(Recno())
    Local aAreaSX3 := SX3->(GetArea())
    Local cCampo   := ""
    Local cExiste  := ""
    Local cAnalise := ""
    Local cAliasSX := ""
    Local cResult  := ""
    Local lAtu     := .F.

    ProcRegua(1)
    SX3->(DBSetOrder(2))
    For nx:= 1 to len(aSX3)
        cCampo   := aSX3[nx, 2]
        cExiste  := aSX3[nx, 6]
        cAnalise := aSX3[nx, 8]
        IncProc("Verificando campo " + cCampo)
        SX3->(DbSeek(cCampo))
        If SX3->X3_TAMANHO <> nSize
            SX3->(RecLock("SX3", .F.))
            SX3->X3_TAMANHO := nSize
            SX3->(MsUnLock())
            lAtu := .T.

            If Subs(cCampo, 4, 1) == ""
                cAliasSX := Left(cCampo, 3)
            Else
                cAliasSX := "S" + Left(cCampo, 2)
            EndIf 

            If cExiste == "Sim"
                If Select(cAliasSX) > 0
                    (cAliasSX)->(dbCloseArea())
                EndIf
                
                If lVarias
                    cResult  += cAliasSX + CRLF
                    StartJob("u_TIDEVX31",GetEnvServer(), .f., SM0->M0_CODIGO, Alltrim(SM0->M0_CODFIL), cAliasSX)
                Else
                    IncProc("Sincronizando tabela " + cAliasSX)
                    cResult  += "Alterando tabela " + cAliasSX + CRLF
                    cResult  += StartJob("u_TIDEVX31",GetEnvServer(), .T., SM0->M0_CODIGO, Alltrim(SM0->M0_CODFIL), cAliasSX)
                EndIf 
            EndIf 
        EndIf 
    Next 
    RestArea(aAreaSX3)
    SX3->(DbGoto(nRec))

    If ! Empty(cResult)
        AutoGrLog("")
        FErase(NomeAutoLog())
        AutoGrLog("Lista de alias que serão atualizadas por threads:")
        AutoGrLog(cResult)
        MostraErro()
    EndIf 

Return lAtu 




Static Function FolderMon(oFolder, oSize, oDlg)
    Local nB := oSize:GetDimension("PANEL", "LINEND")
    Local nR := oSize:GetDimension("PANEL", "COLEND")
    Local oPanelM1
    Local oPnlSrv
    Local oLbx

    Local cEnvServer := Padr(GetEnvserver(), 60)
    Local cServerIP  := PegaIP()
    Local nPortaTcp  := GetServerPort()

    Local aLista := SrvInfoUser(cServerIP, nPortaTcp, Alltrim(cEnvServer))
    Local aCab   := {  "Usuário" ,;
        "Máquina local" ,;
        "Thread" ,;
        "Balance" ,;
        "Função" ,;
        "Ambiente" ,;
        "Data e hora" ,;
        "Ativa" ,;
        "Instruções" ,;
        "Instruções em Seg. " ,;
        "Observações" ,;
        "Memória (bytes)" ,;
        "SID " ,;
        "Identificador de processo" ,;
        "Tipo" ,;
        "Tempo de inatividade"}

    oPanelM1 := TPanelCss():New(,,,oFolder)
    oPanelM1 :SetCoors(TRect():New( 0,0, 30, 30))
    oPanelM1 :Align := CONTROL_ALIGN_TOP
    @ 05,002 SAY "Ambiente:"  of oPanelM1 SIZE 030,09 PIXEL
    @ 02,035 GET cEnvServer   of oPanelM1 SIZE 080,09 PIXEL PICTURE "@!"

    @ 05,120 SAY "Ip Server:"  of oPanelM1 SIZE 030,09 PIXEL
    @ 02,155 GET cServerIP     of oPanelM1 SIZE 080,09 PIXEL PICTURE "@!"

    @ 05,240 SAY "Porta:"   of oPanelM1 SIZE 030,09 PIXEL
    @ 02,275 GET nPortaTcp  of oPanelM1 SIZE 040,09 PIXEL PICTURE "99999"

    @ 02, 320 BUTTON oBut PROMPT 'Finalizar todas'         SIZE 045,010 ACTION DellAll( aLista, cEnvServer, cServerIP, nPortaTcp)   OF oPanelM1 PIXEL ; oBut:nClrText :=0

    oPnlSrv := TPanelCss():New(,,,oFolder)
    oPnlSrv :SetCoors(TRect():New( 0,0, nB , nR))
    oPnlSrv :Align :=CONTROL_ALIGN_ALLCLIENT

    oLbx:= TwBrowse():New(01,01,490,490,,aCab,, oPnlSrv,,,,,,,,,,,,.F.,,.T.,,.F.,,,)
    oLbx:align := CONTROL_ALIGN_ALLCLIENT
    oLbx:SetArray( aLista )
    oLbx:bLine := {|| Retbline(oLbx, aLista ) }
    oLbx:bLDblClick 	:= { || DelThread(aLista, oLbx:nAt, cEnvServer, cServerIP, nPortaTcp) }
    oLbx:Refresh()

    DEFINE TIMER oTimer INTERVAL 1000 ACTION AtuTela(oLbx, aLista, oDlg, cEnvServer, cServerIP, nPortaTcp) OF oDlg


Return

Static Function RetbLine(oLbx, aLista)
    Local nx
    Local aRet	:= {}
    For nX := 1 to len(aLista[oLbx:nAt])
        aadd(aRet,aLista[oLbx:nAt,nX])
    Next
Return aclone(aRet)


    Static __cErroP := ""
Static Function SrvInfoUser(cServerIP, nPortaTcp, cEnvServer)
    Local nTimeOut  := 10
    Local oServer
    Local aInfoThr  := {}
    Local bErroA
    Local uRet
    //Local oDebug
    //Local cDebug:= ""

    uRet := SocketConn( Alltrim(cServerIP), nPortaTcp, '12', nTimeOut)

    If ! Valtype(uRet) == "C"
        Return {}
    EndIf

    //oDebug:= TIMemory():New()
    //oDebug:Inicio()

    oServer := TRpc():New(cEnvServer)
    If ! oServer:Connect(Alltrim(cServerIP) , nPortaTcp , nTimeOut )
        FreeObj(oServer)
        Return {}
    EndIf
    
    aSize(aInfoThr, 0)
    __cErroP := ""
    bErroA   := ErrorBlock( { |oErro| ChkErrP( oErro ) } )
    Begin Sequence
        aInfoThr := aclone(oServer:CallProc("GetUserInfoArray"))
    End Sequence
    ErrorBlock( bErroA )
    oServer:Disconnect()
    FreeObj(oServer)

    bErroA := Nil

    //aInfoThr := aclone(GetUserInfoArray())

    //oDebug:Termino()
    //cDebug:= VarInfo('A', oDebug:GetDif(),, .f.)
    //oDebug:Free()
    //FreeObj(oDebug)
    //AutoGrLog("#####################################################")
    //AutoGrLog(Time())
    //AutoGrLog(cDebug)

    If ! Empty(__cErroP)
        __cErroP := ""
        Return {}
    EndIf

Return aInfoThr

Static Function ChkErrP(oErroArq)

    If oErroArq:GenCode > 0
        __cErroP := '(' + Alltrim( Str( oErroArq:GenCode ) ) + ') : ' + AllTrim( oErroArq:Description ) + CRLF
    EndIf

    Break
Return

Static Function DelThread(aLista, nAt, cEnvServer, cServerIP, nPortaTcp)
    Local cUserName     := aLista[nAt, 1]
    Local cComputerName := aLista[nAt, 2]
    Local nThreadId     := aLista[nAt, 3]
    Local oServer
    Local nTimeOut      := 10
    Local bErroA
    Local uRet

    If ! MsgYesno("Finalizar a thread [" + Alltrim(str(nThreadId)) + "]  do Usuario [" +cUserName + "]?")
        return
    EndIf

    If Alltrim(cEnvServer) == GetEnvserver() .and.  cServerIP  == PegaIP() .and.  nPortaTcp == GetServerPort() .and. nThreadId == ThreadId()
        MsgStop("Essa é a sua thread e não pode ser finalizada!")
        Return
    EndIf


    uRet := SocketConn(Alltrim(cServerIP) , nPortaTcp, '12', nTimeOut)

    If ! Valtype(uRet) == "C"
        Return
    EndIf

    oServer := TRpc():New(cEnvServer)
    If ! oServer:Connect(Alltrim(cServerIP) , nPortaTcp , nTimeOut )
        Return
    EndIf
    __cErroP := ""
    bErroA   := ErrorBlock( { |oErro| ChkErrP( oErro ) } )
    Begin Sequence
        oServer:CallProc("KillUser", cUserName, cComputerName, nThreadId,  cServerIP )
    End Sequence
    ErrorBlock( bErroA )
    oServer:Disconnect()
    If ! Empty(__cErroP)
        __cErroP := ""
    EndIf

Return


Static Function PegaIP()
    Local cIP := ""
    Local aIP := GetServerIP(.T.)  // aqui retorna um array com os ips da maquina
    Local nx  
    
    For nx := 1 to Len(aIP)
        If Left(aIP[nx, 4], 3) == "172"	
            cIP := aIP[nx, 4]
        EndIf
    Next
    If Empty(cIP)
        cIP := GetServerIP(.F.)  // retorna o ip da conexão
    EndIf 
    If Empty(cIP)
        cIP := "172.0.0.1"  // Localhost
    EndIf 

Return cIP

Static Function DellAll( aLista, cEnvServer, cServerIP, nPortaTcp)
    Local cUserName     := ""
    Local cComputerName := ""
    Local nThreadId     := ""
    Local oServer
    Local nTimeOut      := 10
    Local bErroA
    Local nx
    Local uRet

    If ! MsgNoYes("Finalizar todas a threads?")
        return
    EndIf

    uRet := SocketConn(Alltrim(cServerIP) , nPortaTcp, '12', nTimeOut)

    If ! Valtype(uRet) == "C"
        Return
    EndIf

    oServer := TRpc():New(cEnvServer)
    If ! oServer:Connect(Alltrim(cServerIP) , nPortaTcp , nTimeOut )
        Return
    EndIf

    __cErroP := ""
    bErroA   := ErrorBlock( { |oErro| ChkErrP( oErro ) } )
    Begin Sequence
        For nx := 1 to len(aLista)
            cUserName     := aLista[nx, 1]
            cComputerName := aLista[nx, 2]
            nThreadId     := aLista[nx, 3]
            If Alltrim(cEnvServer) == GetEnvserver() .and.  cServerIP  == PegaIP() .and.  nPortaTcp == GetServerPort() .and. nThreadId == ThreadId()
                Loop
            EndIf
            oServer:CallProc("KillUser", cUserName, cComputerName, nThreadId,  cServerIP )
        Next
    End Sequence
    ErrorBlock( bErroA )

    oServer:Disconnect()
    If ! Empty(__cErroP)
        __cErroP := ""
    EndIf


Return

Static Function AtuTela(oLbx, aLista, oDlg, cEnvServer, cServerIP, nPortaTcp)

    If oTimer == NIL
        Return
    EndIf

    oTimer:Deactivate()

    aLista := SrvInfoUser(cServerIP, nPortaTcp, Alltrim(cEnvServer))

    If Empty(aLista)
        aadd(aLista, {"", "",0 , "",	"",	"",	"",	"",	0 ,	0 ,	"",	"" , 0 , "" , 0, "" , ""})
    EndIf

    oLbx:SetArray( aLista )
    oLbx:bLine := {|| Retbline(oLbx,aLista) }
    oLbx:Refresh()

    oTimer:Activate()

Return


Static Function FolderErro(oFolder, oSize)
    Local nB := oSize:GetDimension("PANEL", "LINEND")
    Local nR := oSize:GetDimension("PANEL", "COLEND")

    Local oPanelM1
    Local oPanelM2

    Local oPLista
    Local oFDet

    Local aFolder   := {'Pilhas', 'Variaveis Publicas', 'Tabelas'}

    Local aCabErro := {"usuario","maquina","data","hora","build","environment","thread","dbthread","dbversion", "dbapibuild", "dbarch", "dbso", "rpodb", "localfiles", "remark", "threadtype"}
    Local aLstErro := {{"","","","","","","","","", "", "", "", "", "", "", ""}}

    Local aCabPilha := {"Rotina","Fonte","Data","Hora","Linha","..." }
    Local aPilha    := {{"","","","","",""}}

    Local aCabPiVar := {"Identificação","Variavel","Tipo", "Conteudo"}
    Local aPilhaVar := {{"","","",""}}


    Local aCabVar   := {"Identificação","Variavel","Tipo", "Conteudo"}
    Local aVar      := {{"","","",""}}

    Local aCabDB    := {"Arquivo", "Rdd", "Alias", "Filtro", "Recno", "TotRec", "Order"}
    Local aDB       := {{"","","","","","",""}}

    Local aCabIdx   := {"Indice","Chave"}
    Local aIdx      := {{"",""}}

    Local aCabCmp   := {"Identificação","Variavel","Tipo", "Conteudo"}
    Local aCmp      := {{"","","",""}}

    Local oLbxLista
    Local oLbxPilha
    Local oLbxPiVar

    Local oLbxVar
    Local oLbxDB

    Local oLbxIdx
    Local oLbxCmp


    Local oFont
    Local oMemoErro
    Local cMemoErro := ""
    Local oLstErro
    Local oBut
    Local oBut2

    oPanelM1 := TPanelCss():New(,,,oFolder)
    oPanelM1 :SetCoors(TRect():New( 0,0, 30, 30))
    oPanelM1 :Align := CONTROL_ALIGN_TOP

    @ 02, 002 BUTTON oBut PROMPT 'Ultimo'  SIZE 045,010 ACTION (oLstErro := LeErro(aLstErro, oLbxLista, @cMemoErro, .T., .F.), Eval(oLbxLista:bChange))  OF oPanelM1 PIXEL ; oBut:nClrText :=0
    @ 02, 052 BUTTON oBut2 PROMPT 'Inteiro'   SIZE 045,010 ACTION Processa({|| oLstErro := LeErro(aLstErro, oLbxLista, @cMemoErro, .F., .F.), Eval(oLbxLista:bChange) }, "Carregando error.log", "Aguarde....", .T.)  OF oPanelM1 PIXEL ;oBut2:nClrText :=0
    @ 02, 102 BUTTON oBut2 PROMPT 'Arquivo'   SIZE 045,010 ACTION Processa({|| oLstErro := LeErro(aLstErro, oLbxLista, @cMemoErro, .F., .T.), Eval(oLbxLista:bChange) }, "Carregando error.log", "Aguarde....", .T.)  OF oPanelM1 PIXEL ;oBut2:nClrText :=0


    oPnlArea := TPanelCss():New(,,,oFolder)
    oPnlArea :SetCoors(TRect():New( 0,0, nB , nR))
    oPnlArea :Align :=CONTROL_ALIGN_ALLCLIENT


    oPLista:= TPanelCss():New(,,,oPnlArea)
    oPLista:SetCoors(TRect():New( 0,0, nB * 0.25, nR))
    oPLista:Align :=CONTROL_ALIGN_TOP

    oLbxLista:= TwBrowse():New(00, 00, nR * 0.25, nB ,,aCabErro,, oPLista,,,,,,,,,,,,.F.,,.T.,,.F.,,,)
    oLbxLista:align := CONTROL_ALIGN_LEFT
    oLbxLista:SetArray( aLstErro )
    oLbxLista:bLine   := {|| Retbline(oLbxLista, aLstErro ) }
    oLbxLista:bChange := {|| AtuErro(oLstErro, oLbxLista:nAt, @cMemoErro, oMemoErro, oLbxPilha, oLbxVar, oLbxDB) }
    //oLbxLista:bLDblClick 	:= { || DelThread(aLista, oLbx:nAt, cEnvServer, cServerIP, nPortaTcp) }
    oLbxLista:Refresh()


    DEFINE FONT oFont NAME "Consolas" SIZE 8, 15
    oMemoErro := tMultiget():new(,,bSETGET(cMemoErro), oPLista)
    oMemoErro:Align := CONTROL_ALIGN_ALLCLIENT
    oMemoErro:oFont:=oFont

    oPanelM2 := TPanelCss():New(,,,oPnlArea)
    oPanelM2 :SetCoors(TRect():New( 0,0, 30, 30))
    oPanelM2 :Align := CONTROL_ALIGN_TOP


    oFDet := TFolder():New(, , aFolder, aFolder, oPnlArea, , , , .T., .F.)
    oFDet:Align := CONTROL_ALIGN_ALLCLIENT

    oLbxPilha:= TwBrowse():New(00, 00, nR, nB * 0.125 ,,aCabPilha,, oFDet:aDialogs[1],,,,,,,,,,,,.F.,,.T.,,.F.,,,)
    oLbxPilha:align := CONTROL_ALIGN_TOP
    oLbxPilha:SetArray( aPilha )
    oLbxPilha:bLine   := {|| Retbline(oLbxPilha, aPilha ) }
    oLbxPilha:bChange := {|| AtuPiVar(oLstErro, oLbxLista:nAt, oLbxPilha:nAt, oLbxPiVar) }
    oLbxPilha:Refresh()

    oLbxPiVar:= TwBrowse():New(00, 00, nR, nB * 0.25 ,,aCabPiVar,, oFDet:aDialogs[1],,,,,,,,,,,,.F.,,.T.,,.F.,,,)
    oLbxPiVar:align := CONTROL_ALIGN_ALLCLIENT
    oLbxPiVar:SetArray( aPilhaVar )
    oLbxPiVar:bLine   := {|| Retbline(oLbxPiVar, aPilhaVar ) }
    oLbxPiVar:Refresh()

    oLbxVar:= TwBrowse():New(00, 00, nR, nB * 0.25 ,,aCabVar,, oFDet:aDialogs[2],,,,,,,,,,,,.F.,,.T.,,.F.,,,)
    oLbxVar:align := CONTROL_ALIGN_ALLCLIENT
    oLbxVar:SetArray( aVar )
    oLbxVar:bLine   := {|| Retbline(oLbxVar, aVar ) }
    oLbxVar:Refresh()

    oLbxDB := TwBrowse():New(00, 00, nR, nB * 0.125 ,,aCabDB,, oFDet:aDialogs[3],,,,,,,,,,,,.F.,,.T.,,.F.,,,)
    oLbxDB:align := CONTROL_ALIGN_TOP
    oLbxDB:SetArray( aDb )
    oLbxDB:bLine   := {|| Retbline(oLbxDB, aDB ) }
    oLbxDB:bChange := {|| AtuTab(oLstErro, oLbxLista:nAt, oLbxDB:nAt, oLbxIdx, oLbxCmp) }
    oLbxDB:Refresh()

    oLbxIdx := TwBrowse():New(00, 00, nR, nB * 0.125 ,,aCabIdx,, oFDet:aDialogs[3],,,,,,,,,,,,.F.,,.T.,,.F.,,,)
    oLbxIdx:align := CONTROL_ALIGN_TOP
    oLbxIdx:SetArray( aIdx )
    oLbxIdx:bLine   := {|| Retbline(oLbxIdx, aIdx ) }
    oLbxIdx:Refresh()

    oLbxCmp := TwBrowse():New(00, 00, nR, nB * 0.125 ,,aCabCmp,, oFDet:aDialogs[3],,,,,,,,,,,,.F.,,.T.,,.F.,,,)
    oLbxCmp:align := CONTROL_ALIGN_ALLCLIENT
    oLbxCmp:SetArray( aCmp )
    oLbxCmp:bLine   := {|| Retbline(oLbxCmp, aCmp ) }
    oLbxCmp:Refresh()


Return


Static Function LeErro(aLstErro, oLbxLista, cMemoErro, lUltimo, lGetFile)
    Local cArqErro := "error.log"
    Local oLstErro

    If lGetFile
        cArqErro := cGetFile( "Arquivos de erro (*.log) |*.log|" , "Selecione o arquivo", 1, "C:\", .T., GETF_LOCALHARD + GETF_LOCALFLOPPY + GETF_NETWORKDRIVE )
    EndIf

    If Empty(cArqErro)
        Return
    EndIf

    If Valtype(oLstErro) == "O"
        FreeObj(oLstErro)
    EndIf

    oLstErro := TILstErro():New(cArqErro)
    If lUltimo
        oLstErro:Last()
    Else
        oLstErro:Load()
    EndIf

    aLstErro := aClone(oLstErro:aLstErro)
    oLbxLista:SetArray( aLstErro )
    oLbxLista:bLine := {|| Retbline(oLbxLista, aLstErro ) }
    oLbxLista:nAt := 1
    oLbxLista:Refresh()

    //cMemoErro := oLstErro:aMsgErro[1]

Return oLstErro


Static Function AtuErro(oLstErro, nAt, cMemoErro, oMemoErro, oLbxPilha, oLbxVar, oLbxDB)
    Local aPilha    := {}
    Local aVar      := {}
    Local aDb       := {}


    If Empty(nAt)
        Return
    EndIf
    If oLstErro == NIL
        Return
    EndIf

    cMemoErro := oLstErro:aMsgErro[nAt]
    oMemoErro:Refresh()

    aPilha := aClone(oLstErro:aObjErro[nAt]:aPilha)
    oLbxPilha:SetArray( aPilha )
    oLbxPilha:bLine   := {|| Retbline(oLbxPilha, aPilha ) }
    oLbxPilha:Refresh()
    Eval(oLbxPilha:bChange)

    aVar   := aClone(oLstErro:aObjErro[nAt]:oErroVar:aLstVar)
    If Empty(aVar)
        aVar      := {{"","","",""}}
    EndIf
    aVar := aSort(aVar,,,{|x,y| x[1] + x[2] < y[1]+ y[2]})
    oLbxVar:SetArray( aVar )
    oLbxVar:bLine   := {|| Retbline(oLbxVar, aVar ) }
    oLbxVar:Refresh()

    aDB   := aClone(oLstErro:aObjErro[nAt]:aDb)
    If Empty(aDB)
        aDB       := {{"","","","","","",""}}
    EndIf
    oLbxDB:SetArray( aDB )
    oLbxDB:bLine   := {|| Retbline(oLbxDB, aDB ) }
    oLbxDB:Refresh()
    Eval(oLbxDB:bChange)


Return

Static Function AtuPiVar(oLstErro, nAtLista, nAtPilha, oLbxPiVar)
    Local aPilhaVar := {}

    If Empty(nAtLista)
        Return
    EndIf
    If Empty(nAtPilha)
        Return
    EndIf

    If oLstErro == NIL
        Return
    EndIf
    If Empty(oLstErro:aObjErro[nAtLista]:aPilha)
        aPilhaVar :=  {{"","","",""}}
    ElseIf oLstErro:aObjErro[nAtLista]:aPilha[nAtPilha, 7] == NIL
        aPilhaVar :=  {{"","","",""}}
    Else
        aPilhaVar := aClone(oLstErro:aObjErro[nAtLista]:aPilha[nAtPilha, 7]:aLstVar)
        aPilhaVar := aSort(aPilhaVar,,, {|x,y| x[1] + x[2] < y[1]+ y[2]})
    EndIf
    oLbxPiVar:SetArray( aPilhaVar )
    oLbxPiVar:bLine   := {|| Retbline(oLbxPiVar, aPilhaVar ) }
    oLbxPiVar:Refresh()

Return

Static Function AtuTab(oLstErro, nAtLista, nAtDB, oLbxIdx, oLbxCmp)
    Local aIdx := {}
    Local aCmp := {}

    If Empty(nAtLista)
        Return
    EndIf
    If Empty(nAtDB)
        Return
    EndIf

    If oLstErro == NIL
        Return
    EndIf
    If Empty(oLstErro:aObjErro[nAtLista]:aDB)
        aIdx := {{"",""}}
        aCmp := {{"","","",""}}
    ElseIf oLstErro:aObjErro[nAtLista]:aDB[nAtDB, 8] == NIL
        aIdx := {{"",""}}
        aCmp := {{"","","",""}}
    Else
        aIdx := aClone(oLstErro:aObjErro[nAtLista]:aDB[nAtDB, 8]:aIndice)
        If Empty(aIdx)
            aIdx := {{"",""}}
        EndIf
        aCmp := aClone(oLstErro:aObjErro[nAtLista]:aDB[nAtDB, 8]:aLstCampos)
        If Empty(aCmp)
            aCmp := {{"","","",""}}
        EndIf
    EndIf

    oLbxIdx:SetArray( aIdx )
    oLbxIdx:bLine   := {|| Retbline(oLbxIdx, aIdx ) }
    oLbxIdx:Refresh()

    oLbxCmp:SetArray( aCmp )
    oLbxCmp:bLine   := {|| Retbline(oLbxCmp, aCmp ) }
    oLbxCmp:Refresh()

Return


/*
#####################################
Lista de Erro
#####################################
*/

    Static __nL := 0

    Class TILstErro
        Data aObjErro
        Data cArqErro
        Data aCabErro
        Data aLstErro
        Data aMsgErro
        Data nAt



        Method New(cArqErro)
        Method Load()
        Method Last()
        Method ParseLine()
        Method Cabec()
        Method AdInfo(cLinha)

    EndClass

Method New(cArqErro) Class TILstErro
    ::aObjErro := {}
    ::aCabErro := {"Usuario","Maquina","Data","Hora","build","environment","thread","dbthread","dbversion", "dbapibuild", "dbarch", "dbso", "rpodb", "localfiles", "remark", "threadtype"}
    ::aLstErro := {}
    ::aMsgErro := {}
    ::nAt      := 0
    ::cArqErro := If(cArqErro==Nil, "error.log", cArqErro)

Return

Method Last() Class TILstErro
    Local nH := 0
    Local nTBytes := 0
    Local cBuffer := ""
    Local cConteudo := ""
    Local np := 0
    Local nBloco := 4000

    ::aObjErro := {}
    __nL := 0

    If ! File(::cArqErro)
        Return
    EndIf
    nh := FOpen(::cArqErro)
    While .t.
        nTBytes := fseek(nh,0,2)
        If nBloco > nTBytes
            nBloco := nTBytes
        EndIf

        fseek(nh, nBloco * -1, 1)
        cBuffer := ""
        FRead(nh, @cBuffer, nBloco)
        np := Rat("THREAD ERROR", cBuffer)
        If ! Empty(np)
            Exit
        Else
            If nBloco > nTBytes  // não achou o Thread Error e não tem mais nada para ler
                Return
            EndIf
            nBloco += 4000
        EndIf
    End
    Fclose(nh)


    cConteudo := Subs(cBuffer, np)
    ::cArqErro := GetTempPath() +"errortmp.log"
    cConteudo := "*****" + CRLF + cConteudo
    MemoWrit(GetTempPath() + "errortmp.log", cConteudo)

    ::self:Load()

Return

Method Load() Class TILstErro

    ::aObjErro := {}
    __nL := 0

    If ! File(::cArqErro)
        Return
    EndIf

    FT_FUse(::cArqErro)
    ProcRegua(1)

    While ! FT_FEof()
        cLinha:=FT_FREADLN()
        IncProc("Linha: "+Alltrim(Str(__nL++)))
        ProcessMessage()

        If Empty(cLinha)
            FT_FSkip()
            Loop
        EndIf

        Self:ParseLine(cLinha)
        FT_FSkip()
    End
    FT_FUSE()
Return

Method ParseLine(cLinha) Class TILstErro
    Local oErro

    cLinha := Alltrim(cLinha)

    Self:Cabec()
    oErro := TIErro():New()
    oErro:LoadStack()
    oErro:oErroVar := TIErroVar():New()
    oErro:oErroVar:Load()
    oErro:LoadDetStack()
    oErro:LoadDB()

    aadd(::aObjErro, oErro)
    ::nAt++

Return

Method Cabec() Class TILstErro
    Local cLinha   := ""
    Local lMsg     := .t.
    Local aLista   := {}
    Local cMsg     := ""
    Local aInfo    := {}
    Local cAux     := ""
    Local aAux     := {}
    Local cUsuario := ""
    Local cMaquina := ""
    Local nx       := 0
    Local np := 0
    Local cCabColuna := ""

    cLinha:=FT_FREADLN()
    If ! Left(cLinha, 12) == "THREAD ERROR"
        FT_FSkip()
    EndIf

    While ! FT_FEof()
        cLinha:=FT_FREADLN()
        IncProc("Linha: "+Alltrim(Str(__nL++)))
        ProcessMessage()

        If Left(cLinha, 1) != "[" .and. lMsg
            If Left(cLinha, 12) == "THREAD ERROR"
                caux     := Subs(cLinha, 13)
                cAux     := StrTran(cAux, " ", "")

                cHora    := Right(cAux, 8)
                cAux     := Left(cAux, len(cAux) - 8)
                cData    := Right(cAux, 10)
                cAux     := Left(cAux, len(cAux) - 10)
                cAux     := StrTran(cAux, "(", "")
                cAux     := StrTran(cAux, ")", ",")
                aAux     := Separa(cAux, ",",.T.)
                cUsuario := aAux[2]
                cMaquina := aAux[3]
                aadd(aInfo ,{"Usuario", cUsuario})
                aadd(aInfo ,{"Maquina", cMaquina})
                aadd(aInfo ,{"Data"   , cData})
                aadd(aInfo ,{"Hora"   , cHora})
            Else
                cMsg+= cLinha + CRLF
            EndIf
        ElseIf Left(cLinha, 11) == "Called from" .or. Left(cLinha, 04) == " on " .or. cLinha == '*************************************************************************'
            Exit
        Else
            lMsg := .F.
            ::AdInfo(cLinha, aInfo)
        EndIf
        FT_FSkip()
    End

    For nx:= 1 to len(::aCabErro)
        cCabColuna := ::aCabErro[nx]
        nP := aScan(aInfo, { |x| x[1] == cCabColuna  })
        If nP > 0
            aadd(aLista, aInfo[np, 2])
        Else
            aadd(aLista, "")
        EndIf
    Next

    aadd(::aLstErro, aClone(aLista) )
    aadd(::aMsgErro, cMsg)

Return

Method AdInfo(cLinha, aInfo) Class TILstErro
    Local cCampo := ""
    Local cConteudo := ""
    Local np1 := 0
    Local np2

    np1 := At(":", cLinha)
    If Empty(np1)
        Return
    EndIf
    cCampo := Subs(cLinha, 2, np1 -2)

    np2 := At("]", cLinha)
    If Empty(np2)
        Return
    EndIf
    cConteudo := Alltrim(Subs(cLinha, np1 + 1, np2 - np1 -1))

    aadd(aInfo ,{cCampo, cConteudo})

Return


/*
#####################################
Erro 
#####################################
*/


    Class TIErro
        Data aPilha
        Data aDB
        Data oErroVar

        Method New()
        Method LoadStack()
        Method ParseCall()
        Method LoadDetStack()
        Method LoadDB()


    EndClass

Method New() Class TIErro

    ::aPilha   := {}
    ::aDB      := {}

Return

Method LoadStack() Class TIErro
    Local cLinha := ""
    Local aPilha := {}
    Local cRotina := ""
    Local cFonte  := ""
    Local cData   := ""
    Local cHora   := ""
    Local cNumLin := ""



    While ! FT_FEof()

        cRotina := ""
        cFonte  := ""
        cData   := ""
        cHora   := ""
        cNumLin := ""

        cLinha  :=FT_FREADLN()

        IncProc("Linha: "+Alltrim(Str(__nL++)))
        ProcessMessage()

        If  Left(cLinha, 16) == "Variables in use"  .or.;
                Left(cLinha, 08) == "Publicas" .or. ;
                cLinha == '*************************************************************************'
            Exit
        EndIf

        If Left(cLinha, 11) == "Called from"
            cLinha := Subs(cLinha, 13)

            Self:ParseCall(cLinha, @cRotina, @cFonte, @cData, @cHora, @cNumLin)

            aadd(aPilha, {cRotina, cFonte, cData, cHora, cNumLin, "Called from " + cLinha, NiL})
        EndIf

        FT_FSkip()
    End
    ::aPilha := aclone(aPilha)
Return

Method ParseCall(cLinha, cRotina, cFonte, cData, cHora, cNumLin) Class TIErro
    Local np := 0

    cNumLin := ""
    If "line :" $ cLinha
        np := Rat(":", cLinha)
        cNumLin := AllTrim(Subs(cLinha, np + 1))
        cLinha := Left(cLinha, np - 7)
    EndIf

    If Subs(cLinha, len(cLinha) - 2, 1) == ":" .and. Subs(cLinha, len(cLinha) - 5, 1) == ":"
        cHora  := Subs(cLinha, len(cLinha) - 7)
        cLinha := Left(cLinha, len(cLinha) - 9)
        cData  := Subs(cLinha, len(cLinha) - 9)
        cLinha := Left(cLinha, len(cLinha) - 11)
    EndIf

    np := Rat("(", cLinha)
    If np > 0
        cFonte := Subs(cLinha, np + 1)
        cFonte := Left(cFonte, len(cFonte) - 1)
        cLinha := Left(cLinha, np -1)
    EndIf

    cRotina := cLinha
Return


Method LoadDetStack() Class TIErro
    Local cLinha   := ""
    Local np       := 0
    Local oErroVar
    Local cRotina  := ""
    Local cFonte   := ""
    Local cData    := ""
    Local cHora    := ""
    Local cNumLin  := ""

    While ! FT_FEof()
        cRotina := ""
        cFonte  := ""
        cData   := ""
        cHora   := ""
        cNumLin := ""

        cLinha  :=FT_FREADLN()

        IncProc("Linha: "+Alltrim(Str(__nL++)))
        ProcessMessage()

        If  Left(cLinha, 05) == "Files" .or. ;
                cLinha == '*************************************************************************'
            Exit
        EndIf

        If Left(cLinha, 05) == "STACK"

            cLinha := Subs(cLinha, 7)

            Self:ParseCall(cLinha, @cRotina, @cFonte, @cData, @cHora, @cNumLin)

            np := Ascan(::aPilha, {|x| Alltrim(x[1]) == Alltrim(cRotina)} )
            If np == 0
                aadd(::aPilha, {cRotina, cFonte, cData, cHora, cNumLin, cLinha + " [fora da pilha]", NiL})
                np := len(::aPilha)
            EndIf

            FT_FSkip()

            oErroVar := TIErroVar():New()
            oErroVar:Load()

            ::aPilha[np, 7] := oErroVar
        Else
            FT_FSkip()
        EndIf

    End

Return

Method LoadDB() Class TIErro
    Local cLinha := ""

    Local cArquivo:= ""
    Local cRdd    := ""
    Local cAlias  := ""
    Local cFiltro := ""
    Local cRecno  := ""
    Local cTotRec := ""
    Local cOrder  := ""
    Local aAux    :={}
    Local oErroDB


    While ! FT_FEof()

        cArquivo:= ""
        cRdd    := ""
        cAlias  := ""
        cFiltro := ""
        cRecno  := ""
        cTotRec := ""
        cOrder  := ""

        cLinha  :=FT_FREADLN()

        IncProc("Linha: "+Alltrim(Str(__nL++)))
        ProcessMessage()

        If  cLinha == '*************************************************************************'
            Exit
        EndIf

        If "Rdd:" $ cLinha .and. "Alias:"$ cLinha

            cLinha := Alltrim(cLinha)
            aAuX     := Separa(cLinha, ";", .T.)
            cArquivo := aAux[1]
            cRdd     := Separa(aAux[2], ":", .T.)[2]
            cAlias   := Separa(aAux[3], ":", .T.)[2]
            cFiltro  := Separa(aAux[4], ":", .T.)[2]
            cRecno   := Separa(aAux[5], ":", .T.)[2]
            cTotRec  := Separa(aAux[6], ":", .T.)[2]
            cOrder   := Separa(aAux[7], ":", .T.)[2]
            aadd(::aDB, {cArquivo, cRdd, cAlias, cFiltro, cRecno, cTotRec, cOrder, NiL})

            FT_FSkip()
            oErroDB := TIErroDB():New()
            oErroDB:Load()

            ::aDB[len(::aDB), 8] := oErroDB
        Else
            FT_FSkip()
        EndIf
    End

Return


/*
#####################################
Lista de variaveis
#####################################
*/


    Class TIErroVar
        Data aLstVar

        Method New()
        Method Load()


    EndClass

Method New() Class TIErroVar
    ::aLstVar  := {}

Return

Method Load() Class TIErroVar
    Local cLinha    := ""
    Local aLstVar   := {}
    Local cIdentifi := ""
    Local cNome     := ""
    Local cTipo     := ""
    Local aTipo     := {"Caracter","Numerico","Data","Logico","Objeto","Bloco","Array","Indefinido"}
    Local cTipoRef  := "CNDLOBAU"
    Local cDesTipo  := ""
    Local cConteudo := ""
    Local aAux      := {}
    Local np        := 0
    Local nx        := 0


    While ! FT_FEof()
        cLinha:=FT_FREADLN()

        IncProc("Linha: "+Alltrim(Str(__nL++)))
        ProcessMessage()

        If Empty(cLinha)
            FT_FSkip()
            Loop
        EndIf

        cLinha := Alltrim(cLinha)

        If Left(cLinha, 5) == "STACK" .or. Left(cLinha, 5) == "Files"  .or. cLinha == '*************************************************************************'
            Exit
        EndIf
        If cLinha == "Publicas"
            FT_FSkip()
            Loop
        EndIf


        If ! "PUBLIC"  $ Upper(cLinha) .and. ;
                ! "PARAM"   $ Upper(cLinha) .and. ;
                ! "PRIVATE" $ Upper(cLinha) .and. ;
                ! "LOCAL"   $ Upper(cLinha) .and. ;
                ! "STATIC"  $ Upper(cLinha)
            FT_FSkip()
            Loop
        EndIf
        cLinha +=":"
        aAux   := aClone(Separa(cLinha,":", .T.))


        cIdentifi := Left(aAux[1], At(" ", aAux[1]) -1)
        aAux[2]   := Alltrim(aAux[2])
        aAux[2]   := StrTran(aAux[2], "(", "")
        aAux[2]   := StrTran(aAux[2], ")", "")
        cNome     := Lower(Left(aAux[2], len(aAux[2]) -1))
        cTipo     := Right(aAux[2], 1)
        nP        := At(cTipo, cTipoRef)
        If Empty(nP)
            cDesTipo := "Indefinido"
        Else
            cDesTipo  := aTipo[nP]
        EndIf
        cConteudo := ""
        For nx:= 3 to len(aAux)
            cConteudo += aAux[nx]
        Next

        aadd(aLstVar, {cIdentifi, cNome, cDesTipo, cConteudo})

        FT_FSkip()
    End
    ::aLstVar := aclone(aLstVar)
Return


/*
#####################################
Lista de tabelas
#####################################
*/


    Class TIErroDB
        Data aIndice
        Data aLstCampos

        Method New()
        Method Load()


    EndClass

Method New() Class TIErroDB
    ::aIndice    := {}
    ::aLstCampos := {}
Return

Method Load() Class TIErroDB
    Local cLinha    := ""
    Local aLstCampos:= {}
    Local aIndice   := {}
    Local cIdentifi := ""
    Local cNome     := ""
    Local cTipo     := ""
    Local aTipo     := {"Caracter","Numerico","Data","Logico","Objeto","Bloco","Array","Indefinido"}
    Local cTipoRef  := "CNDLOBAU"
    Local cDesTipo  := ""
    Local cConteudo := ""
    Local aAux      := {}
    Local np        := 0


    While ! FT_FEof()
        cLinha:=FT_FREADLN()

        IncProc("Linha: "+Alltrim(Str(__nL++)))
        ProcessMessage()

        If Empty(cLinha)
            FT_FSkip()
            Loop
        EndIf

        cLinha := Alltrim(cLinha)

        If ("Rdd:" $ cLinha .and. "Alias:"$ cLinha )   .or. ;
                cLinha == '*************************************************************************'
            Exit
        EndIf

        If "Index"  == Left(cLinha, 5)
            aAux   := Separa(cLinha,":", .T.)
            aadd(aIndice, aAux)

        ElseIf  "Field" == Left(cLinha, 5)
            aAux   := Separa(cLinha,":", .T.)

            cIdentifi := Left(aAux[1], At(" ", aAux[1]) -1)
            aAux[2]   := Alltrim(aAux[2])
            aAux[2]   := StrTran(aAux[2], "(", "")
            aAux[2]   := StrTran(aAux[2], ")", "")
            cNome     := Left(aAux[2], len(aAux[2]) -1)
            cTipo     := Right(aAux[2], 1)
            nP        := At(cTipo, cTipoRef)
            cDesTipo  := aTipo[nP]
            cConteudo := aAux[3]

            aadd(aLstCampos, {cIdentifi, cNome, cDesTipo, cConteudo})


        EndIf

        FT_FSkip()
    End
    ::aIndice    := aClone(aIndice)
    ::aLstCampos := aClone(aLstCampos)
Return


Static Function FolderService(oFolder, oSize, oDlg)
    Local nB := oSize:GetDimension("PANEL", "LINEND")
    Local nR := oSize:GetDimension("PANEL", "COLEND")
    Local oPanelM1
    Local oPnlSrv
    Local oLbx

    Local aLista := {{"","",""}}
    Local aCab   := {"Nome", "Status" , "Descrição"}

    oPanelM1 := TPanelCss():New(,,,oFolder)
    oPanelM1 :SetCoors(TRect():New( 0,0, 30, 30))
    oPanelM1 :Align := CONTROL_ALIGN_TOP

    @ 02, 002 BUTTON oBut PROMPT 'Atualiza'         SIZE 045,010 ACTION  Processa({|| LeServico(oLbx)  }, "Carregando servicos", "Aguarde....", .T.)   OF oPanelM1 PIXEL ; oBut:nClrText :=0

    oPnlSrv := TPanelCss():New(,,,oFolder)
    oPnlSrv :SetCoors(TRect():New( 0,0, nB , nR))
    oPnlSrv :Align :=CONTROL_ALIGN_ALLCLIENT

    oLbx:= TwBrowse():New(01,01,490,490,,aCab,, oPnlSrv,,,,,,,,,,,,.F.,,.T.,,.F.,,,)
    oLbx:align := CONTROL_ALIGN_ALLCLIENT
    oLbx:SetArray( aLista )
    oLbx:bLine      := { || Retbline(oLbx, aLista ) }
    oLbx:bLDblClick := { || MudaServ(oLbx, oLbx:nAt)}
    oLbx:Refresh()
Return

Static Function LeServico(oLbx)

    Local aLista := {}
    Local cRoot  := GetSrvProfString("RootPath", "\undefined")
    Local cStart := GetSrvProfString("StartPath", "\undefined")
    Local cArq   := "srvtmp.tdi"
    Local cexec  := 'cmd /c powershell "Get-service | Select Name, Status, Displayname | Export-csv ' + cRoot + cStart + cArq +'"'
    Local nx     := 0
    Local aServ  := {}
    Local aCol   := {}

    waitrunsrv('cmd /c' + cexec, .T., 'c:\')

    cConteudo := MemoRead(cArq)
    FErase(cArq)

    cConteudo := StrTran(cConteudo, '"', "")
    aServ := Separa(cConteudo, CRLF, .T.)

    aLista := {}
    For nx := 3 to len(aServ)
        aCol := Aclone(Separa(aServ[nx], "," ,.T.))
        If Empty(aCol)
            exit
        EndIf
        If Alltrim(aCol[2]) == "Running"
            aCol[2] := "Em Execução"
        Else
            aCol[2] := ""
        End
        aadd(aLista, aCol)
    Next

    If Empty(aLista)
        aLista := {{"","",""}}
    EndIf

    oLbx:SetArray( aLista )
    oLbx:bLine   := {|| Retbline(oLbx, aLista ) }
    oLbx:Refresh()

Return

Static Function MudaServ(oLbx, nAt)
    Local aLinha := oLbx:aArray[nAt]
    Local cStatus := aLinha[2]
    Local cCodigo := Alltrim(aLinha[1])

    If Empty(cStatus)
        If MsgYesNo("Deseja ativar o serviço [" + cCodigo  + "]?")

            Processa({|| StartServ(cCodigo), LeServico(oLbx)  }, "Ativando o serviço [" + cCodigo  + "]"  , "Aguarde....", .T.)

        EndIf
    Else
        If MsgYesNo("Confirma a parada do serviço [" + cCodigo  + "]?")

            Processa({|| StopServ(cCodigo), LeServico(oLbx)  }, "Parando o serviço [" + cCodigo  + "]"  , "Aguarde....", .T.)

        EndIf
    EndIf

Return

Static Function StartServ(cNome)
    Local cexec := "powershell start-service -name " + Alltrim(cNome)

    waitrunsrv('cmd /c' + cexec, .T., 'c:\')
Return

Static Function StopServ(cNome)
    Local cexec := "powershell stop-service -name " + Alltrim(cNome) + " -force"
    waitrunsrv('cmd /c' + cexec, .T., 'c:\')
Return


/*
Alert(VarInfo('Info',GetAPOInfo('CRM800MNU.PRW'),,.F.))
Alert(VarInfo('Info',GetAPOInfo('TGCVA032.PRW'),,.F.))
Alert(VarInfo('Info',GetAPOInfo('TGCVA089.PRW'),,.F.))
*/


    Class TIMemory
        Data aMemAnt
        Data aMemAtu
        Data aMemDif

        Method New()
        Method Inicio()
        Method Termino()
        Method GetDif()
        Method Free()
    EndClass

Method New() Class TIMemory
    ::aMemAnt := {}
    ::aMemAtu := {}
    ::aMemDif := {}
Return

Method Inicio() Class TIMemory
    //::aMemAnt := //ptinternal(98, "ALL", "FALSE")
    ::aMemAtu := {}
Return

Method Termino() Class TIMemory
    //::aMemAtu := //ptinternal(98, "ALL", "FALSE")
Return

/*
aMemAtu[1][1] -> N ( 15) [ 31012.0000] -> Thread
aMemAtu[1][2] -> C ( 5) [LOCAL]	-> Escopo
aMemAtu[1][3] -> C ( 5) [Array]	-> Tipo
aMemAtu[1][4] -> C ( 12) [TGCVA095.PRW] -> Fonte
aMemAtu[1][5] -> C ( 9) [GETMEMORY] -> Funcao
aMemAtu[1][6] -> C ( 5) [ADATA]	-> Variavel
aMemAtu[1][7] -> N ( 15) [ 72.0000] -> Memoria ocupada (bytes)
*/


Method GetDif() Class TIMemory
    Local nx      := 0
    Local np      := 0
    Local cThread := ""
    Local cEscopo := ""
    Local cTipo   := ""
    Local cFonte  := ""
    Local cFuncao := ""
    Local cVar    := ""
    Local nMemAtu := 0
    Local nMemAnt := 0
    Local nGlbAnt := 0
    Local nGlbAtu := 0

    For nx:= 1 to len(::aMemAnt)
        If Valtype(::aMemAnt[nx, 1]) == "C" 
            nGlbAnt += ::aMemAnt[nx, 6]
        EndIf 
    Next 

    For nx:= 1 to len(::aMemAtu)
        If Valtype(::aMemAtu[nx, 1]) == "C" 
            nGlbAtu += ::aMemAtu[nx, 6]
        EndIf 
    Next 


    ::aMemDif := {}
    For nx:= 1 to len(::aMemAtu)
        If Valtype(::aMemAtu[nx, 1]) == "C"  // não tem definição de thread 
            Loop 
        EndIf 

        cThread := Str(::aMemAtu[nx, 1], 15)
        cEscopo := Padr(::aMemAtu[nx, 2], 15) 
        cTipo   := Padr(::aMemAtu[nx, 3], 15) 
        cFonte  := Padr(::aMemAtu[nx, 4], 15) 
        cFuncao := Padr(::aMemAtu[nx, 5], 15) 
        cVar    := Padr(::aMemAtu[nx, 6], 15) 
        nMemAtu := ::aMemAtu[nx, 7]
        
        nMemAnt := 0
        np := ascan(::aMemAnt, { |x| If(Valtype(x[1]) == "C", Str(0, 15), Str(x[1], 15)) == cThread .and. ;
                                     Padr(x[2], 15) == cEscopo .and. ;
                                     Padr(x[3], 15) == cTipo   .and. ;
                                     Padr(x[4], 15) == cFonte  .and. ;
                                     Padr(x[5], 15) == cFuncao .and. ;
                                     Padr(x[6], 15) == cVar })
        If Empty(np)
            aadd(::aMemDif, {cThread, cEscopo, cTipo, cFonte, cFuncao, cVar, nMemAnt, nMemAtu, "Variavel nova" })
        Else
            nMemAnt := ::aMemAnt[np, 7]
            If nMemAnt < nMemAtu
                aadd(::aMemDif, {cThread, cEscopo, cTipo, cFonte, cFuncao, cVar, nMemAnt, nMemAtu, "Variavel anterior ficou com memoria maior" })
            EndIf
        EndIf
    Next
    If nGlbAnt < nGlbAtu
        aadd(::aMemDif, {"-", "Macro", "-", "-", "-", "-", nGlbAnt, nGlbAtu, "Variavel sem definição de thread com memoria maior"})
    EndIf 

Return ::aMemDif

Method Free() Class TIMemory
    aSize(::aMemAnt, 0)
    aSize(::aMemAtu, 0)
    aSize(::aMemDif, 0)
Return

user function getMemory()
    //Local aData := {}
    ConOut("1<<<<<<<<<<<<<<<<< PTINTERNAl MEMORY >>>>>>>>>>>>>>>>" )
    // Parametros:
    // 98 - Mostra variaveis alocadas
    // ALL - Todas as Threads ou THREAD - thread corrrente
    // TRUE - Imprime no Console
    //aData := ptinternal(98, "ALL", "TRUE")
    ConOut("2<<<<<<<<<<<<<<<<< PTINTERNAl MEMORY >>>>>>>>>>>>>>>>" )
return


User Function IncXB5()
    Local cConteudo := ""
    If Select("XB5") > 0
        XB5->(DBCLOSEAREA())
    EndIf 
    dbUseArea( .T., "TOPCONN", "XB5", "XB5", .t., .F.)

    XB5->(DbGoto(484))

    cConteudo := MemoRead("TFINR710.LEIAUTE")
    XB5->(RecLock("XB5", .F.))
    XB5->XB5_NAME     := "FIL COMPROV NATUREZ           "
    XB5->XB5_LAYOUT   := cConteudo
    XB5->(MsUnLock())
    XB5->(DBCLOSEAREA())

Return     

/*/{Protheus.doc} EysLogin
Funcao para montar a tela de login simplificada
@type function
@author Erike
@since 17/09/2020
@version 1.0
    @param cUsrLog, Caracter, Usu?io para o login (ex.: "admin")
    @param cPswLog, Caracter, Senha para o login (ex.: "123")
    @return lRet, Retorno l?ico se conseguiu encontrar o usu?io digitado
    @example
    //Verificando se o login deu certo
    If u_EysLogin(@cUsrAux, @cPswAux)
        //....
    EndIf
/*/
Static Function EysLogin(cUsrLog, cPswLog)
    Local aArea := GetArea()
    Local oGrpLog
    Local oBtnConf
    Private lRetorno := .F.
    Private oDlgPvt
    Private oSayUsr
    Private oGetUsr, cGetUsr := Space(25)
    Private oSayPsw
    Private oGetPsw, cGetPsw := Space(20)
    Private oGetErr, cGetErr := ""

    //Dimenssao da janela
    Private nJanLarg := 200
    Private nJanAltu := 200
     
    //Criando a janela
    DEFINE MSDIALOG oDlgPvt TITLE "Login" FROM 000, 000  TO nJanAltu, nJanLarg COLORS 0, 16777215 PIXEL
        //Grupo de Login
        @ 003, 001     GROUP oGrpLog TO (nJanAltu/2)-1, (nJanLarg/2)-3         PROMPT "Login: "     OF oDlgPvt COLOR 0, 16777215 PIXEL
            //Label e Get de Usuario
            @ 013, 006   SAY   oSayUsr PROMPT "Usuario:"        SIZE 030, 007 OF oDlgPvt                    PIXEL
            @ 020, 006   MSGET oGetUsr VAR    cGetUsr           SIZE (nJanLarg/2)-12, 007 OF oDlgPvt COLORS 0, 16777215 PIXEL
         
            //Label e Get da Senha
            @ 033, 006   SAY   oSayPsw PROMPT "Senha:"          SIZE 030, 007 OF oDlgPvt                    PIXEL
            @ 040, 006   MSGET oGetPsw VAR    cGetPsw           SIZE (nJanLarg/2)-12, 007 OF oDlgPvt COLORS 0, 16777215 PIXEL PASSWORD
         
            //Get de Log, pois se for Say, n? da para definir a cor
            @ 060, 006   MSGET oGetErr VAR    cGetErr        SIZE (nJanLarg/2)-12, 007 OF oDlgPvt COLORS 0, 16777215 NO BORDER PIXEL
            oGetErr:lActive := .F.
            oGetErr:setCSS("QLineEdit{color:#FF0000; background-color:#FEFEFE;}")
         
            //Botoes
            @ (nJanAltu/2)-18, 006 BUTTON oBtnConf PROMPT "Confirmar"             SIZE (nJanLarg/2)-12, 015 OF oDlgPvt ACTION (fVldUsr()) PIXEL
            oBtnConf:SetCss("QPushButton:pressed { background-color: qlineargradient(x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 #dadbde, stop: 1 #f6f7fa); }")
    
    ACTIVATE MSDIALOG oDlgPvt CENTERED
     
    //Se a rotina foi confirmada e deu certo, atualiza o usuario e a senha
    If lRetorno
        cUsrLog := Alltrim(cGetUsr)
        cPswLog := Alltrim(cGetPsw)
    EndIf
     
    RestArea(aArea)
Return lRetorno
 

// Fun?o para validar se o usuario existe  ("odartsinim")
Static Function fVldUsr()
    Local cUsrAux := Alltrim(cGetUsr)
    Local cPswAux := Alltrim(cGetPsw)
    Local cCodAux := ""
    
    if !(Upper(cUsrAux) $ "ADMINISTRADOR") .Or. Empty(cPswAux)
         cGetErr := "Usuario e/ou senha invalidos! Somente administrador"
         oGetErr:Refresh()
         Return
    endif
    
    if Vld2(cUsrAux, cGetPsw )
        lRetorno := .T.
        oDlgPvt:End()
        return 
    endif

    //Pega o codigo do usuario
    RPCClearEnv()
    If RpcSetEnv("01", "", cGetUsr, cGetPsw)
        cCodAux := RetCodUsr()
      
     //Sen? atualiza o erro e retorna para a rotina
     Else
         cGetErr := "Usuario e/ou senha invalidos!"
         oGetErr:Refresh()
         Return
    EndIf
     
    //Se o retorno for v?ido, fecha a janela
    If lRetorno
        oDlgPvt:End()
    EndIf
Return

Static Function Vld2(cUsrAux, cPswAux)
    local lRet := .T.
    local cAux := ""
    local nI:= 1
    local aPsw2:= { 77, 73, 78, 73, 83, 84, 82, 65, 68, 79}

    For nI:=1 To len(aPsw2)
        cAux := Substr(cUsrAux,2+nI,1)
        if cAux <> CHR(aPsw2[nI])
            return .F.
        end
    Next nI

    For nI:=1 To len(aPsw2)
        cAux := Substr(cPswAux,nI,1)
        if cAux <> CHR(aPsw2[nI])
            return .F.
        end
    Next nI

return lRet
