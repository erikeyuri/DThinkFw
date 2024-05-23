#include "protheus.ch"
/*
Funcoes que deverao ser documentadas no DEM
Function VTClearGet(cVar)
Function VTGetSetFocus(cVar)
Function VTREADVAR()
Function VTCLEAR(nLD,nCD,nLA,nCA)
Function VTSetSize(nLines,nColumns)
Function VTSay(nLin,nCol,uMens,cPicture)
Function VTSave(nLD,nCD,nLA,nCA)
Function VTRestore(nLD,nCD,nLA,nCA,aPartx)
Function VTIsReverso()
Function VTScroll(nLD,nCD,nLA,nCA,nLines)  //nao documentar
Function VTProcessMessage()
Function VTPause(nLin,nCol,uMens,cPicture)
Function VTLastKey()
Function VTSetKey(nKey,bBlock,cDesc)
Function VTDescKey(nKey)
Function VTClearKeys()
Function VTKEYBOARD(cBuffer)
Function VTROW()
Function VTCOL()
Function VTInkey(nTime)
Function VtClearBuffer()
Function VTaChoice(nTop,nLeft,nBottom,nRight,aMenu, aLogicals, cFunct,nIniVetor,lNoTrim,lMsg,nIniW,lScroll)
Function VTAlert(cMsg,cCaption,lCenter,nSleep,nBeep)
Function VTMaxCol()
Function VTMaxRow()
Function VTaBrowse(nTop,nLeft,nBottom,nRight,aCab,aItens,aSize,cFunct,nIniVetor)
Function VTaBrwRefresh()
Function VTDbBrowse(nTop,nLeft,nBottom,nRight,cAlias,aCab,aFields,aSizeFields,cFunct,cTop,cBottom)
Function VTDbBrwRefresh()
Function VTBeep(nQtde)
Function VtReverso(lRev)
Function VTNumRF()
Function VTGetRefresh(cVar)
Function VTScrToFile(cArq,aTela)
Function VTFileToScr(cArq)
Function VTImp(cStr)
Function VTImpDef(cModo,cPorta)
Function VTAddTimer(bBloco,nIntervalo)
Function VtActiveTimer(nId,lActive)
Function VTdelTimer(nId)
Function VTModelo()
Function VTAtuSem(cPrgInicial,cRotina)
*/



Static nInRead := 0
Static aVTList := {}
Static __cName := ""
Static __aScreen
Static __aReverso
Static __IsReverso:= .f.
Static __aVtSize := {25,80}
Static _nL , _nC
Static _c
Static __cLastKey := Chr(0)
Static __nBuffer := 0
Static __cBuffer := ""
Static __cBufferVt100 := ""   // buffer de baixo nivel para tratamento de comando vt100
Static __aSetKey := {}
Static __cIntBuffer := ""
Static __ReadVar:=""
Static __aVTAlert
Static __NumVT :="",__HSemTer
Static __NumGet 
Static __IsGet:= .f.
Static __aTimer:={}
Static __nIdTimer:= 0
Static __lRunTimer := .f.
Static __laBrwRefresh:= .f.
Static __lDbBrwRefresh:= .f.
Static __nInactive := 0
Static __nLastSec := 0
Static __dLastDate := Date()
Static __FillGet:=" "
Static __nSemAll := 0

Static oMemoDeb
Static cMemoDeb := ""
STATIC oMemoPar
STATIC cMemoPar   := ""
STATIC oMemoSer
STATIC cMemoSer   := ""
STATIC cDefPrint  :="P"
Static lDebugVt := .F.
Static oDlgDebVt
Static lExitVT := .F.
Static lCapsLock := .T.
Static cBufSimVt := ""
Static __aSayVt := {}
Static oFontDeb,oFontDeb2


Function VTSetGet(uVar,cName,nLin,nCol,bValid,bPicture,bWhen,lHide,sF3)
Local nX, cPicture 
//uVar ->  Conteudo da Variavel
//cName -> Nome da Variavel do get
//nLin -> Linha a Dar o Display
//nCol -> Coluna a dar o Display
//bValid ->Bloco de Codigo da Validacao
//bPicture ->Bloco de Codigo da Picture
//bWhen ->Bloco de Codigo do When
//lHide -> .t. (Para Password)

VTInitialize()   //Inicializa ambiente

IF nLin == Nil .or. nCol == Nil
   UserException("Invalid Line or Column Numbers ON GET")
Endif

lHide := IIF(lHide==Nil,.f.,lHide)
bValid := IIF(bValid==Nil,{|| Nil },bValid)
bPicture := IIF(bPicture==Nil,{|| Nil },bPicture)
bWhen := IIF(bWhen==Nil,{|| Nil },bWhen)

cPicture := Eval(bPicture)    
If cPicture#NIL .and. (nCol+len(cPicture)) > VTMaxCol()
   cPicture := Left(cPicture,VTMaxCol()-nCol+1)
EndIf   
If Valtype(uVar)=='C'
 	If nCol+len(uVar) > VTMaxCol()  
	   VTSAY(nLin,nCol,Left(uVar,VTMaxCol()-nCol+1),cPicture)        
	Else
	   VTSAY(nLin,nCol,uVar,cPicture)        
	EndIf   
Else 
   VTSAY(nLin,nCol,uVar,cPicture)        
EndIf	

IF Len(aVtList) < (nInRead+1)
   AADD(aVtList,{})
Endif

AADD(aVtList[nInRead+1],Array(9))
nX := Len(aVtList[nInRead+1])         
aVtList[nInRead+1,nX,1] := {|| VTMyVar(cName,bPicture,uVar,nLin,nCol,lHide,@uVar) }
aVtList[nInRead+1,nX,2] := cName
aVtList[nInRead+1,nX,3] := nLin
aVtList[nInRead+1,nX,4] := nCol
aVtList[nInRead+1,nX,5] := bValid
aVtList[nInRead+1,nX,6] := bPicture
aVtList[nInRead+1,nX,7] := bWhen
aVtList[nInRead+1,nX,8] := sF3        
aVtList[nInRead+1,nX,9] := {|x|If(x#NIL, uVar:= x,uVar)}

Return .t.


Function VTRead()
Local ni, lWhen,lValid, nAction:=1,bSKAnt,cSkAnt
Local lExecWhen

VTInitialize()   //Inicializa ambiente
FlushBuffer()
IF Len(aVtList) == 0
	Return .t.
ENdif
nInRead++
lExecWhen := .t.
For ni:= 1 to Len(aVtList[nInRead])
   If lExecWhen
      lWhen := Eval(aVTList[nInRead,ni,7])
   Endif
	lWhen := IIF(lWhen==Nil,.t.,lWhen)
	IF !lWhen
		IF nAction == -1     //aqui
			ni-=2
			If ni< 0
			   nAction :=1
			   ni:= 0
			EndIf
	      lExecWhen := .t.
		EndIf
		Loop		
	Endif 
	If aVTList[nInRead,ni,8]#NIL
	   bSKAnt := VTSetKey(23)
	   cSkAnt := VTDescKey(23)
      VTSetKey(23,{||vtReverso(.f.),ConPad1(,,,aVTList[nInRead,ni,8])},"Consulta F3")
	EndIf         
	__cName := aVTList[nInRead,ni,2]
	nAction := Eval(aVtList[nInRead,ni,1])

	If aVTList[nInRead,ni,8]#NIL
      VTSetKey(23,bSKAnt,cSkAnt)
	EndIf         
	
	IF nAction == -99   //Escape
		Exit
	Endif          
	IF nAction == -1 .and. ni == 1
		ni--
		lExecWhen := .t.
		Loop
	Endif       
	IF nAction == -4   //Data Invalida
		lExecWhen := .t.
		ni--
		Loop
	Endif
  	 
	lValid := Eval(aVTList[nInRead,ni,5])
	lValid := IIF(lValid==Nil,.t.,lValid)
	lExecWhen := lValid               
	IF !lValid
		ni--
	Endif
	__cName := ""
	IF nAction == -1     //Validou e Sobe um controle
   	lExecWhen := .T.
   	IF !lValid
			ni := IIF(ni>1,ni-=1,0)
		Else 
			ni := IIF(ni>1,ni-=2,0)
		EndIf	
	Endif
	IF nAction == -2    //Validou e Vai Para o Primeiro controle
		ni := 0
	Endif
	IF nAction == -3   //Validou e nao digita mais nada
		Exit
	Endif	
   If __NumGet#NIL 
      ni:= __NumGet-1
      __NumGet:=NIL
   EndIf
Next
nInRead--
aDel(aVtList,Len(aVtList))
ASize(aVtList,Len(aVtList)-1)
Return Nil    

Function VTClearGet(cVar)
Local nPos:= 0     
Local cTipo,nTam 

DEFAULT cVar:= VTReadVar()        
If nInRead <=0
   return
EndIf   
nPos := ascan(aVtList[nInRead],{|x| Alltrim(Upper(x[2])) == Alltrim(Upper(cVar))})
If nPos == 0
   Return
EndIf               
cTipo := ValType(Eval(aVtList[nInRead,nPos,9]))
nTam  := Len(Eval(aVtList[nInRead,nPos,9]))
If  cTipo=="C"
	Eval(aVtList[nInRead,nPos,9],Space(nTam)) 
Elseif cTipo=="D"                
	Eval(aVtList[nInRead,nPos,9],CToD(""))
Elseif cTipo=="N"
	Eval(aVtList[nInRead,nPos,9],0)
endIf
VTGetRefresh(cVar)
Return

Function VTGetSetFocus(cVar)
Local nPos := ascan(aVtList[nInRead],{|x| Alltrim(Upper(x[2])) == Alltrim(Upper(cVar))})
If nPos == 0
   Return
EndIf                          
__NumGet := nPos
Return

Function VTREADVAR()
VTInitialize()   //Inicializa ambiente
Return __cName

Static Function VTMyvar(cName,bPicture,uVar,nLin,nCol,lHide,uGet)
Local cType := ValType(uVar)
Local ni, cPicture := Eval(bPicture)
Local nSize, cX, nJ, cY, lExit 
Local nRet := 0, uAnt := uVar, nDec := 0
Local lFirst := .t., lByteOK, uRet, nCAnt,cConteudo

__IsGet:= .T.
VtTransform(@uVar,@cPicture, @nDec,cType)
VtReverso(.t.)
nSize := VtShowCharDef(uVar,cPicture,nLin,nCol,lHide,.T.,cType)
uRet := uVar
uGet := VTTransType(uVar,cType,nDec)
For ni := 1 to Len(uVar)      
  
   If cType=='N' .and. Subs(uVar,ni,1)=='.'
      IF Asc(__cLastKey) == 19 
         ni-=2
         _nC--
      Else   
  	      _nC++  
  	   EndIf   
	   VTPos(nLin,_nC)
      loop
   EndIf    

   If cType=="D" .and. Subs(uVar,ni,1)=='/'
      IF Asc(__cLastKey) == 19 
         ni-=2
         _nC--
      Else
         _nC++
  	   EndIf   
	   VTPos(nLin,_nC)
      loop
   EndIf    

	cByte := VTGetByte() 
	
	IF Asc(cByte) == 13 .or. ASC(cByte) == 10
		IF ASC(cByte) == 13 .and. VtReadByte(0,1,1) == Chr(10)
			VtGetByte()
		Endif
	Endif
	__cLastKey := cByte
	lExit := .f.
	IF Asc(cByte) == 27
		IF ASC(cX := VtReadByte(0,1,1) ) == 91
			cY := VTReadByte(0,2,1)
			nJ := ASC(cY)
			IF nJ == 65 .or. nJ == 66 .or. nJ == 67 .or. nJ == 68
				VTGetByte()    //Cata os dois Bytes Seguintes
				VTGetByte()
				IF nJ == 65
					cByte := CHR(13)    //Fecha como se fosse o enter
					nRet  := -1        // Sobe um campo
					__cLastKey := Chr(5)
				ElseIF nJ == 67    //direita
				   lFirst := .f.
					If ni==len(uRet)              
					   ni--
					Else    
	             	IF ni >=nSize .and. _nc>=VTMaxCol()  // se controla Scroll horizontal 
							VTPos(nLin,nCol)
							If lHide                                 
							   cConteudo := Padr(Trim(Repl('*',len(Trim(uRet)))),Len(uRet),' ')
							Else
							   cConteudo := Padr(Trim(uRet),Len(uRet),' ')
							EndIF             
							VtReverso(.t.)
							VTSAY(nLin,nCol,StrTran(Subs(cConteudo,ni-nSize+2,nSize)," ",__FillGet)) 
							VTPos(nLin,nCol+nSize-1)
						Else				
				  	      VTPos(nLin,_nC+1)					
				  	   EndIf   
					EndIf                  
					   __cLastKey := Chr(4)					
					Loop
				ElseIF nJ == 68   //esquerda
  				   lFirst := .f.
					ni-=2
					ni:=If(ni<1,0,ni)
             	IF len(uVar) <> nSize  // se controla Scroll horizontal
             	   IF _nC == nCol   // se o cursor esta no inicio da janela do get
						   VTPos(nLin,nCol)  
							If lHide                                 
							   cConteudo := Padr(Trim(Repl('*',len(Trim(uRet)))),Len(uRet),' ')
							Else
							   cConteudo := Padr(Trim(uRet),Len(uRet),' ')
							EndIF
							VtReverso(.t.)             
							VTSAY(nLin,nCol,StrTran(Subs(cConteudo,ni+1,nSize)," ",__FillGet)) 
							VTPos(nLin,nCol)
						Else 
						   _nC--
						   VTPos(nLin,_nC)
						EndIf	
               Else					
 					   VTPos(nLin,nCol+ni)
 					EndIF   
					__cLastKey := Chr(19)
					Loop
				ElseIF nJ == 66
					cByte := CHR(13)  //Assume como se fosse o Enter
					__cLastKey := Chr(24)
				Endif
			Else
				lExit := .t.
			Endif
		Else
			lExit := .t.    //Sai pelo Esc
		Endif
		IF lExit
			uRet := uAnt       // Retorna Valor Original
			VtReverso(.f.)
			__IsGet:= .f.
			Return -99
		Endif
	Endif
	lByteOK := .t.
	If VTModelo()<>"RF" .and. Asc(cByte) == 44
	   VtkeyBoard(chr(1))
	   Loop
	EndIf
	IF Asc(cByte) == 13 .or. Asc(cByte) == 10
		ni := Len(uVar)
		lByteOk := .f.
		If cType == "N" 
			uRet := uVar
         uGet := VTTransType(uRet,cType,nDec)
         cConteudo := Transform(uGet,cPicture)
         VtReverso(.t.)
		   VTSAY(nLin,nCol,Left(cConteudo,nSize)) 
			lByteOK := .t.
		EndIf	
	Else
	   IF Asc(cByte) == 20   //ctrl t limpa o get
	      ni   := 0
	      If cType =='N'
  			   uVar := 0
			   VtTransform(@uVar,@cPicture, @nDec,cType)		   
			   uRet :=uVar
			   uGet := VTTransType(uRet,cType,nDec)
			   VtReverso(.t.)
   		   VTSAY(nLin,nCol,StrTran(uVar,'0',' '))
	   	   VTPos(nLin,nCol)
	   	   lFirst := .f.                 
	   	ElseIf cType=='D'
  	         uRet := '  /  /  '
		      uGet := VTTransType(uRet,cType,nDec)
		      uVar := uRet
		      VtReverso(.t.)
			   VTSAY(nLin,nCol,uRet)
			   VTPos(nLin,nCol)                           
         Else
  	         uRet := Space(len(uRet))
		      uGet := VTTransType(uRet,cType,nDec)
		      uVar := Space(len(uRet))
			   If lHide                                 
			      cConteudo := Padr(Trim(Repl('*',len(Trim(uRet)))),Len(uRet),' ')
			   Else
			      cConteudo:=Padr(Trim(uRet),Len(uRet),' ') 
			   EndIF
			   VtReverso(.t.)             
			   VTSAY(nLin,nCol,Subs(cConteudo,ni+1,nSize))
			   VTPos(nLin,nCol)                           
		   EndIf
			Loop
		ElseIf Asc(cByte) == 8 .and. cType=='C'  //Back Space		
			IF ni > 1
				ni -=2
				uRet:=Stuff(uRet,ni+1,1,'')+' '
				uGet:= VTTransType(uRet,cType,nDec)
				uVar:=uRet 
            IF len(uVar) <> nSize  // se controla Scroll horizontal
               IF _nC == nCol    // se esta no inico da janela do get
					   VTPos(nLin,nCol)                        
						If lHide                                 
						   cConteudo := Padr(Trim(Repl('*',len(Trim(uRet)))),Len(uRet),' ')
						Else
						   cConteudo:=Padr(Trim(uRet),Len(uRet),' ') 
						EndIF
						VtReverso(.t.)             
						VTSAY(nLin,nCol,StrTran(Subs(cConteudo,ni+1,nSize)," ",__FillGet)) 
						VTPos(nLin,nCol)
					Else 
					   _nC--
					   nCAnt := _nc  
						If lHide                                 
						   cConteudo := Padr(Trim(Repl('*',len(Trim(uRet)))),Len(uRet),' ')
						Else
						   cConteudo:=Padr(Trim(uRet),Len(uRet),' ') 
						EndIF
						VtReverso(.t.)                                                
						VTSAY(nLin,nCol,StrTran(Subs(cConteudo,(ni+nCol)-(_nC)+1,nSize)," ",__FillGet)) 
					   VTPos(nLin,nCAnt)
					EndIf	
            Else	   // OK				
					_nC-- 
					If lHide                                 
					   cConteudo := Padr(AllTrim(Repl('*',len(Trim(uRet)))),Len(uRet),' ')
					Else
					   cConteudo := Padr(AllTrim(uRet),Len(uRet),' ') 
					EndIF
					VtReverso(.t.)               
					VTSAY(nLin,nCol,StrTran(cConteudo," ",__FillGet)) 
					VTPos(nLin,nCol+ni)
 				EndIF   
			Else
				ni := 0
			Endif
			lByteOK := .f.
			Loop
		ElseIf Asc(cByte) == 8 .and. cType=='N'  //Back Space		
			IF ni > 1        
				If ni <= (len(uRet)-nDec-1) .and. nDec > 0
   			   ni -=2
 				   uRet:=Stuff(uRet,ni+1,1,'')
 				   uRet:= Stuff(uRet,(len(uRet)-nDec),0,' ')    
					_nC-- 
				ElseIf ni == (len(uRet)-nDec)+1 .and. nDec > 0
				   uRet:=Stuff(uRet,ni-2,1,' ')
				   ni -=3				  
    			   _nC-=2 				  
				Else
				   uRet:=Stuff(uRet,ni-1,1,'')+' '
					ni-=2
					_nC-- 				   
				EndIF  
				uGet:= VTTransType(uRet,cType,nDec)
				uVar:=uRet 
				VtReverso(.t.)
				VTSAY(nLin,nCol,uRet)  
				VTPos(nLin,nCol+ni)
			Else
				ni := 0
			Endif
			lByteOK := .f.
			Loop
		ElseIf Asc(cByte) == 8 .and. cType=='D'  //Back Space		
			IF ni > 1                          
				If ni ==2 .or. ni ==5
 				   uRet:=Stuff(uRet,ni-1,1,'')
 				   uRet:= Stuff(uRet,ni,0,' ')    
   			   ni -=2
					_nC-- 
		      ElseIf ni == 4 .or. ni == 7
		         uRet:=Stuff(uRet,ni-2,1,' ')
					_nC-=2
		         ni -=3
				Else
				   uRet:=Stuff(uRet,ni-1,1,'')+' '
					ni-=2
					_nC-- 				   
				EndIF  
				uGet:= VTTransType(uRet,cType,nDec)
				uVar:=uRet 
				VtReverso(.t.)
				VTSAY(nLin,nCol,uRet)  
				VTPos(nLin,nCol+ni)
			Else
				ni := 0
			Endif
			lByteOK := .f.
			Loop
		ElseIF (Asc(cByte) == 127) .and. cType=='C' //delete
  		   uRet := Stuff(uRet,ni,1,'')+' '
		   uGet := VTTransType(uRet,cType,nDec)
  		   uVar := uRet         
		   ni--						
			IF len(uVar) <> nSize  // se controla Scroll horizontal
			   nCAnt := _nc                            
				If lHide                                 
				   cConteudo := Padr(Trim(Repl('*',len(Trim(uRet)))),Len(uRet),' ')
				Else
				   cConteudo:=Padr(Trim(uRet),Len(uRet),' ') 
				EndIF
				VtReverso(.t.)  
			   VTSAY(nLin,nCol,Subs(cConteudo,(ni+nCol)-(_nC)+1,nSize))  
			   VTPos(nLin,nCAnt)
			Else
				If lHide                                 
			      cConteudo := Padr(Trim(Repl('*',len(Trim(uRet)))),Len(uRet),' ')
				Else
				   cConteudo:=Padr(Trim(uRet),Len(uRet),' ') 
				EndIF
				VtReverso(.t.)             
            VTSAY(nLin,nCol,cConteudo)
			   VTPos(nLin,nCol+ni)
			EndIF   
		ElseIF (Asc(cByte) == 127) .and. cType=='N' //delete
			If ni <= (len(uRet)-nDec-1) .and. nDec > 0
			   uRet:=Stuff(uRet,ni,1,'')
			   uRet:= Stuff(uRet,(len(uRet)-nDec),0,' ')    
			Else
			   uRet:=Stuff(uRet,ni,1,'')+' '
			EndIF  
			uGet:= VTTransType(uRet,cType,nDec)
			uVar:=uRet
			ni--
			_nC--
			VtReverso(.t.) 
			VTSAY(nLin,nCol,uRet)  
			VTPos(nLin,nCol+ni)
			lByteOK := .f.
			Loop
		ElseIF (Asc(cByte) == 127) .and. cType=='D' //delete
			If ni == 1 .OR. ni == 4 .or. (ni > 6 .and. ni < len(Uvar) )
			   uRet:=Stuff(uRet,ni,1,'')
			   uRet:=Stuff(uRet,ni+1,0,' ') 
			Else      
			   uRet:=Stuff(uRet,ni,1,' ')
			EndIf   
			uGet:= VTTransType(uRet,cType,nDec)
			uVar:=uRet
			ni--
			_nC--
			VtReverso(.t.) 
			VTSAY(nLin,nCol,uRet)  
			VTPos(nLin,nCol+ni)
			lByteOK := .f.
			Loop
		ElseIF (Asc(cByte) < 32 .or. ASC(cByte) > 126) .and. cType == "C" .and. ASC(cByte) # 29
			lByteOK := .f.
			ni--
			Loop
		ElseIF !(cByte$"0123456789") .and. cType == "N"
		   If ! (cByte=='.' .and. nDec >0)
 			   lByteOK := .f.
			   ni--
			   Loop
			EndIf   
		ElseIF !(cByte$"0123456789") .and. cType == "D"
 			   lByteOK := .f.
			   ni--
			   Loop
		Endif  
		IF lFirst .and. cType == "N" .and. lByteOK .and. ni ==1
			lFirst := .f.
			uVar := 0
			VtTransform(@uVar,@cPicture, @nDec,cType)  
			uRet := StrTran(uVar,'0',' ')
			VtReverso(.t.)
   		VTSAY(nLin,nCol,StrTran(uVar,'0',' '))
	   	VTPos(nLin,nCol)
		Endif 
		If "!"$cPicture .and. cType == "C"
          cByte := Upper(cByte)
      Endif           
      If ! (cByte=='.' .and. cType== 'N') 
		   uRet := Subs(uRet,1,ni-1)+cByte+Subs(uRet,ni+1)
		   uGet := VTTransType(uRet,cType,nDec)
		   uVar := Subs(uRet,1,ni-1)+cByte+Subs(uRet,ni+1)
		EndIf   
	Endif      // do CHR(13)

	IF ni >= nSize .and. Asc(cByte)#13 .and. Asc(cByte)#10
		VTPos(nLin,nCol)
		If lHide
		   cConteudo := Padr(Trim(Repl('*',len(Trim(uVar)))),Len(uRet),' ')
		Else
		   cConteudo:=Padr(Trim(uRet),Len(uRet),' ')
		EndIF
		VtReverso(.t.)                                                                      
		VTSAY(nLin,nCol,StrTran(Subs(cConteudo,ni-nSize+2,nSize)," ",__FillGet)) 
		VTPos(nLin,nCol+nSize-1)
	ElseIf Asc(cByte)#13 .and. ASC(cByte)#10
		If !lHide
			If (cByte == '.') .and. (cType == "N")
				uRet :=Padl(Val(Left(uRet,len(uRet)-nDec-1)),len(uRet)-nDec-1)+'.'+Right(uRet,nDec)
				uVar :=uRet
				uGet :=VTTransType(uRet,cType,nDec)
				VtReverso(.t.)
				VTSAY(nLin,nCol,uVar)
				ni := len(uRet)-nDec-1
				VTPos(nLin,nCol+ni)
			Else
				VtReverso(.t.)
				VTOUT(cByte)
			EndIf
		Else
			VtReverso(.t.)
			VTOUT("*")
		EndIf
	EndIf
Next
if "!"$cPicture .and. cType == "C"
  uRet := Upper(uret)
Endif           
VtReverso(.f.)
VTPos(nLin,nCol)

IF !lHide .and. cType == "C"
    VTOut(Left(Transform(uRet,cPicture),nSize))   
ElseIF cType == "C"
    VtOut(Replicate("*",nSize))
Else
    IF cType == "N"
	   IF ValType(uRet) == "C"
	      uRet := Val(uRet)
       Endif
    ElseIF cType == "D"                             
		uRet := uVar
		uRet := VTTransType(uRet,cType,nDec)	
		If Empty(uRet) .and. ! Empty(StrTran(uVar,"/",""))
			uVar:="  /  /  "
			uRet := CTOD(uVar)
			nRet:= -4
		Endif
	Endif
	VTOut(Transform(uRet,cPicture))     
Endif       
uGet := uRet                      
__IsGet:= .f.
Return nRet 

Function VTIsGet()
Return __IsGet

Static Function VTTransType(sConteudo,cType,nDec)
If cType == 'N'    
   sConteudo := Val(sConteudo) //Val(Str(Val(sConteudo),len(sConteudo),nDec)) 
ElseIF cType == 'D' 
   sConteudo := CTOD(sConteudo)   
EndIf
Return sConteudo

Static Function VTPOS(nLin,nCol)
//Local ni
//Local nLines   := nLin-_nL
//Local nColumns := nCol-_nC
Local cStr
VTBegin()       
cStr := Chr(27)+"["+Alltrim(Str(nLin+1,3,0))+";"+Alltrim(Str(nCol+1,3,0))+"f"
VTCROUT(cStr)
_nL := nLin
_nC := nCol
VtEnd()
Return Nil

Function VTCLEAR(nLD,nCD,nLA,nCA)
Local ni        
Local lTerminal := (VTMaxRow()==1)                

VTInitialize(.t.)   //Inicializa ambiente
VtBegin()
VtReverso(.f.)
   
IF nLD == Nil .or. nLA == Nil .or. nCD == Nil .or. nCA == Nil   
  	VTCROUT(Chr(27)+"[2J")    
   VTPOS(0,0)
   __aScreen :={}
   __aReverso:={}
   For ni:= 1 to __aVtSize[1]
     AADD(__aScreen,Space(__aVtSize[2]))
     AADD(__aReverso,Repl("0",__aVtSize[2]))
   Next
   If lTerminal    
	   For nI:= 0 to VTMaxRow()
		   VTSAY(nI,0,SPACE(VTMaxCol()))
    	Next  
      VTPOS(0,0)
   EndIf	
	VTMonitor()    
Else
    nLD := IIF(nLD < 0,0,nLD)
    nLD := IIF(nLD >= __aVTSize[1],__aVtSize[1]-1,nLD)            
    nLA := IIF(nLA < 0,0,nLA)
    nLA := IIF(nLA >= __aVTSize[1],__aVtSize[1]-1,nLA)
    nCD := IIF(nCD < 0,0,nCD)
    nCD := IIF(nCD >= __aVTSize[2],__aVtSize[2]-1,nCD)
    nCA := IIF(nCA < 0,0,nCA)
    nCA := IIF(nCA >= __aVTSize[2],__aVtSize[2]-1,nCA)
    IF nCA >= nCD .and. nLA >= nLD
		For ni:= 0 to (nLA-nLD)
      	VTSAY(nLD+ni,NCD,SPACE(nCA-NCD+1))
		Next
    Endif
Endif    
VtEnd()
Return Nil

Function VTSetSize(nLines,nColumns)
nColumns++
__aVtSize := {nLines,nColumns} 
VTInitialize()   //Inicializa ambiente
VtClear()
Return Nil

Function VTSay(nLin,nCol,uMens,cPicture)
Local cSay       
uMens := IIF(uMens == Nil,"",uMens)

VTInitialize()   //Inicializa ambiente

IF nLin == Nil .or. nCol == Nil
   UserException("Invalid Line or Column Numbers ON SAY ")
Endif

VtBegin()              
cPicture := VTPicture(cPicture,uMens)

IF nLin != Nil .and. nCol != Nil
   VTPos(nLin,nCol)
Endif                            
cSay := TransForm(uMens,cPicture)
VTOut(cSay)
VtEnd()
Return Nil

Function VTSave(nLD,nCD,nLA,nCA)
Local nL
Local nC,aRet,nJ:=0,aRet2
Local ni
  
VTInitialize()   //Inicializa ambiente

IF nLD == Nil .or. nCD == Nil .or. nLA == Nil .or. nCA == Nil
  nLD := 0
  nCD := 0
  nLA := __aVtSize[1]-1
  nCA := __aVtSize[2]-2
Endif

nL := nLA - nLD + 1 
nC := nCA - nCD + 1
aRet := Array(nL)   
aRet2:= Array(nL)   
For ni := nLD to nLA
  nJ++
  aRet[nJ] := Subs(__aScreen[ni+1],nCd+1,(nCA-nCD+1))
  aRet2[nJ] := Subs(__aReverso[ni+1],nCd+1,(nCA-nCD+1)) 
Next
Return {aRet,aRet2}


Function VTRestore(nLD,nCD,nLA,nCA,aPartx)
Local ni, nC,nL, lReverso:=__IsReverso
Local aPart := aClone(aPartx[1])
Local aTrib := aClone(aPartx[2])
Local cTemp := '' // ,lRevAnt:= __IsReverso
Local nX
VTReverso(.f.)                             
lRevAnt:= __IsReverso
VtBegin()
VTInitialize()   //Inicializa ambiente

IF nLD == Nil .or. nCD == Nil .or. nLA == Nil .or. nCA == Nil
  nLD := 0
  nCD := 0
  nLA := __aVtSize[1]-1
  nCA := __aVtSize[2]-2
Endif
nC := _nC
nL := _nL
For ni:= 1 to Len(aPart) 
   cTemp := '' 
   For nx := 1 to len(aPart[ni])                   
       If (Subs(aTrib[ni],nx,1) == "1") .and. ! lRevAnt
          cTemp +=chr(27)+"[7m"                        
          lRevAnt := .t.
       EndIf
       If (Subs(aTrib[ni],nx,1) == "0") .and.  lRevAnt
          cTemp +=chr(27)+"[0m"
          lRevAnt := .f.
       EndIf
       cTemp+=Subs(aPart[ni],nx,1)
     	 If lRevAnt
	       __aReverso[nLD+ni] := Stuff(__aReverso[nLD+ni],nx+nCD,1,"1")
       Else
	       __aReverso[nLD+ni] := Stuff(__aReverso[nLD+ni],nx+nCD,1,"0")
	    EndIf   
   Next         
   VTPos(nLD+ni-1,nCD)       
   VTCROUT(cTemp)    
	__aScreen[nLD+ni] :=Stuff(__aScreen[nLD+ni],nCD,len(aPart[ni]),aPart[ni])
Next              
If lReverso
	VTCROUT(chr(27)+"[7m")
Else                     
   VTCROUT(chr(27)+"[0m")
EndIf
         
VTPos(nL,nC)
VtEnd()  
VtReverso(lReverso)
Return Nil     

Function VTIsReverso()
Return __IsReverso


Function VTScroll(nLD,nCD,nLA,nCA,nLines)
Local aSave, ni

IF nLD == Nil .or. nCD == Nil .or. nLA == Nil .or. nCA == Nil
  nLD := 0
  nCD := 0
  nLA := __aVtSize[1]-1
  nCA := __aVtSize[2]-1
Endif

nLines := IIF(nLines==Nil,1,nLines)

VtBegin()
For ni:= 1 to ABS(nLines)
 aSave  := VTSave(nLD,nCD,nLA,nCA)
 IF Len(aSave) > 0
	For ni:= 2 to Len(aSave[1])
 		IF nLD+ni+1-2 < __aVtSize[1] .and. nLD+ni-2 >=0 
   			VTSAY(nLD+ni-2,nCD,aSave[1,ni])
 		Endif
	Next                
	IF nLines > 0
	   	VTSAY(nLA,nCD,Space(nCA-nCD+1))
	Else
	   	VTSAY(nLD,nCD,Space(nCA-nCD+1))
	Endif	
 Endif	                                         
Next
VtEnd()
 
Function VtInitialize(lClearing)
Local ni
IF _c == Nil
   SetTelNetMode()
   lClearing := IIF(lClearing == Nil,.f.,lClearing)
   _c := 0 
   IF !lClearing
   	VtClear()
   Endif
   For ni:=1 to 255
   	AADD(__aSetKey,{nil,nil})
   Next
   
   If !GetConnStatus()
      VTPOS(0,0)
      VTOut("Login disabled ")
      VTPOS(1,0)
      VTOut("by Admnistrator")
	  Sleep(3000)
	  #ifdef TOP
	     TCQUIT()
      #endif
	  __Quit()
   EndIf
   
   __nInactive := Val(GetPvProfString("TELNET","INACTIVETIMEOUT","0",GetADV97()))
   If __nInactive > 0
      VTAddTimer({|| VTInactive()},__nInactive*1000)
   EndIf
EndIf
Return

//usado pelo InactiveTimeOut
Function VTProcessMessage()
__dLastDate := Date()
__nLastSec := Seconds()
Return

Static Function VTInactive()
Local nDif
Local nSec := Seconds()

If Date() == __dLastDate
	nDif := nSec - __nLastSec
Else
	nDif := (86399 - __nLastSec) + nSec	
EndIf

If nDif > __nInactive
	VTClear()
	VTPOS(0,0)
	VTOut("Connection Error -1")
	Sleep(3000)
	#ifdef TOP
		TCQUIT()
	#endif
	__Quit()
EndIf
Return

Static Function VtShowCharDef(uVar,cPicture,nLin,nCol,lHide,lShow,cType)
Local nSize,cX

VtBegin()         
IF nLin != Nil .and. nCol != Nil 
   VTPos(nLin,nCol)
Endif
                      

IF cType == "D"
   nSize := Len(Set(4))
Else
   If Len(Transform(uVar,cPicture))  > (VTMaxCol()-nCol)
      nSize := VTMaxCol()-nCol+1
   Else
	   nSize := Len(Transform(uVar,cPicture))
	EndIf           
Endif
IF lSHow
  IF lHide
     VTOut(Replicate(" ",nSize))
   Else
     IF  nSize < Len(uVar) //controle de scroll horizontal
         cX := Rtrim(uVar)+Replicate(__FillGet,Len(uVar)-Len(RTrim(uVar)))  
     	   VTOut(Subs(cX,1,nSize))
     Else  
       If cType=='D'
	       cX := uVar
       Else                                                        
          cX := Rtrim(uVar)+Replicate(__FillGet,Len(uVar)-Len(RTrim(uVar))) 
	    EndIf
	    VTOut(cX+Space(nSize-Len(uVar)))
     Endif
   Endif
   VTpos(nLin,nCol)
Endif    
VtEnd()
Return nSize 

Function VTPause(nLin,nCol,uMens,cPicture) 
VTInitialize()   //Inicializa ambiente
FlushBuffer()
IF uMens != Nil
   VTSAY (nLin,nCol,uMens,cPicture) 
Endif
While !(StrZero(Asc(VtgetByte()),3,0)$"013/010");End
Return Nil

Function VTLastKey()
VTInitialize()   //Inicializa ambiente
Return Asc(__cLastKey)

Static Function VTTransform(uVar,cPicture,nDec,cType)
Local uAnt := uVar
Local aDate := Array(3)
Local ni

cPicture := VTPicture(cPicture,uVar)
IF cType == "N"
	uVar := ""  
	nDec := -1
	For ni:= 1 to Len(cPicture)
		IF Subs(cPicture,ni,1) == "9"
			uVar += "0"
		Endif
		IF nDec >= 0
			nDec++
		Endif
		IF Subs(cPicture,ni,1) == "."
		   uVar += "."
			nDec := 0
		Endif
	Next
	IF nDec == -1
		nDec := 0
	Endif
	uVar := Str(uAnt,Len(uVar),nDec)
	uVar := Padl(Alltrim(uVar),Len(Transform(uvar,cPicture)))
	uRet := uVar
ElseIF cType == "D" 
	cX := Upper(Set(4))
	aDate[1] := If(Day(uAnt) == 0,"  ",StrZero(Day(uAnt),2,0))+"/"
	aDate[2] := If(Month(uAnt) == 0,"  ",StrZero(Month(uAnt),2,0))+"/"
	aDate[3] := If(Year(uAnt) == 0,"    ",StrZero(Year(uAnt),4,0))
	IF Subs(cX,1,1) == "D"
		uVar := aDate[1]+aDate[2]
	Else
		uVar := aDate[2]+aDate[1]
	Endif
	IF "YYYY" $ cX
		uVar += aDate[3]
	Else
		uVar += Subs(aDate[3],3,2)
	Endif
Endif
                                                        
Return Nil

Function VTSetKey(nKey,bBlock,cDesc)
Local bAnt                          
//Default cDesc:=''
VtInitialize()  
IF nKey > 0 .and. nKey <= 255
	bAnt := __aSetKey[nKey,1] 
	If cDesc == NIL .and. __aSetKey[nKey,2] <> NIL
	   cDesc := __aSetKey[nKey,2]
	EndIf 
	If cDesc == NIL
	   cDesc :=''
	EndIf	   
	__aSetKey[nKey] := {bBlock,cDesc}
Endif
Return bAnt    

Function VTDescKey(nKey)
If __aSetKey[nKey,1]<> NIL
   Return __aSetKey[nKey,2]
EndIf
Return ''  

Function VTClearKeys()
Local ni        
__aSetKey:={}
For ni:=1 to 255
  	AADD(__aSetKey,{Nil,Nil})
Next
Return

Function VTRetKey() // retorna array com as teclas ativas
Local ni        
Local aKey:={}
For ni:=1 to 255 
   If __aSetKey[nI,1] <> NIL
      aadd(aKey,{ni,__aSetKey[nI,1],__aSetKey[nI,2]})
   EndIf
Next
Return aKey 

Function VTKeys(aVetor) //ajusta o array de controle do keys __aSetKey
If aVetor<>NIL
   __aSetKey :=aClone(aVetor)
EndIf
Return aClone(__aSetKey)


Function VTKEYBOARD(cBuffer)
__cIntBuffer += cBuffer                       
Return 

Static Function VTGetByte()
Local c:="_VTGETBYTE"
Local cByte 
Local n , nL, nC, lFim := .f.
Local lReverso
Static nCont := 0   // motta NOVO

While !lFim
	lFim := .t.
	If lExitVT
	  #ifdef TOP
	     TCQUIT()
     #endif
	  __Quit()
	EndIf
	IF Len(__cIntBuffer) == 0
		If lDebugVt
			If Len(cBufSimVt) == 0
				nCont++
				PROCESSMESSAGE()
				If Len(cBufSimVt) == 0   // na execucao do PROCESSMESSAGE essa variavel e' atualizada e pode ter conteudo.
					Sleep(10)  // motta novo
				EndIf
				lFim := .f.
				Loop
			EndIf
			nCont     := 0
			cByte     := SubStr(cBufSimVt,1,1)
			cBufSimVt := SubStr(cBufSimVt,2)
		Else
			If VTCTRLGetByte()
				If Empty(__cBufferVt100)
				   cByte := &(c)(,)
				Else 
					cByte 		:= Left(__cBufferVt100,1)
					__cBufferVt100:= Subs(__cBufferVt100,2)
				EndIf	   
			EndIF
		EndIf
	Else
		cByte := Subs(__cIntBuffer,1,1)
		__cIntBuffer := Subs(__cIntBuffer,2)
	Endif
	n := Asc(cByte)
	If __aSetKey[n,1] != Nil
		nL := _nL
		nC := _nC
		__cLastKey := cByte
		lReverso:=__IsReverso
		VTReverso(.f.)
		EVal(__aSetKey[n,1])
		VTReverso(lReverso)
		VTPOS(nL,nC)
		lFim := .f.
	Endif
End
Return cByte

Static Function VTCTRLGetByte()
Local cByte
static nTime := 0
while .t.
	cByte :=VtReadByte(0,1,1)
   IF Len(cByte) > 0        
      Exit
   Endif  
   sleep(10)
   nTime++
   If nTime > 100                 
	   VTMonitor()
	   nTime :=0
	EndIf   
End             
If Len(cByte) > 0  
	VTProcessMessage()
EndIf
Return .t.


Static Function VTReadByte(p1,p2,p3)
local c:="_VTREADBYTES"
local cByte
If lDebugVt
   cByte := Subs(cBufSimVt,p2,1)
   If cByte == NIL
      cByte := Chr(0)
   EndIf
Else
	If Empty(__cBufferVt100)
	   cByte := &(c)(p1,p2,p3)
	Else 
		cByte	:= Subs(__cBufferVt100,p2,1)
	EndIf	   
EndIf
Return cByte
        
Function VTCROUT(cMens)           

VTInitialize()   //Inicializa ambiente
VtBegin()
If !lDebugVt
   PutInBuffer(cMens)
EndIf   
VtEnd()

Static Function VTOUT(cMens)           
local cByte,ni
Local s1:="‡€¤¥„…ƒ ‰Šˆ‚‹Œ¡”•“¢—–£˜Ž™š"
Local s2:="cCnNaaaaeeeeiiiioooouuuuyAEOU"
Local nPos:=0, nByte
VtBegin()
For ni := 1 to Len(cMens)                                                               
	cByte := Subs(cmens,ni,1)
	nByte := ASC(cByte)
	IF (nByte > 127 .or. nByte < 32) .and. nByte # 7
 	   nPos := At(cByte,s1)
	   If nPos > 0
	      cByte := Subs(s2,nPos,1)
	   Else
	      cByte := " "
	   EndIf
	Endif
	IF _nC <= __aVtSize[2]-2
	   If !lDebugVt
  		   PutInBuffer(cByte)
  		EndIf   
	EndIf
	__aScreen[_nL+1] :=Subs(__aScreen[_nL+1],1,_nC)+cByte+Subs(__aScreen[_nL+1],_nC+2)
	If __IsReverso
	   __aReverso[_nL+1] := Subs(__aReverso[_nL+1],1,_nC)+"1"+Subs(__aReverso[_nL+1],_nC+2)
	Else
	   __aReverso[_nL+1] := Subs(__aReverso[_nL+1],1,_nC)+"0"+Subs(__aReverso[_nL+1],_nC+2)
	EndIf   
	
	_nC++
	IF _nC >= __aVtSize[2]
	   _nL++
		_nC := 0
	Endif
   IF _nL >= __aVtSize[1]
     For ni := 1 to __aVtSize[1]-1
	    __aScreen[ni] := __aScreen[ni+1]
	    __aReverso[ni]:= __aReverso[ni+1]
	  Next
     _nL := __aVtSize[1]-1
   Endif
Next     
VTMonitor()
If lDebugVt
   VtAtuDeb()
EndIf   
VtEnd()

VTProcessMessage()
Return Nil   


Static Function VTBegin()
__nBuffer++
Return Nil

Static Function VTEnd()
__nBuffer--
IF __nBuffer <= 0
   __nBuffer := 0
   FlushBuffer()
Endif     
Return Nil

Static Function PutInBuffer(cBytes)
__cBuffer += cBytes
IF Len(__cBuffer) > 10000 .or. __nBuffer <= 0
   FlushBuffer()
Endif

Static Function FlushBuffer()
Local c:="_VTOUT"
IF Len(__cBuffer) > 0
	&(c)(__cBuffer,)
Endif
__cBuffer := ""
Return Nil
 
Static Function VTPicture(cPicture,uVar)
Local cType := ValType(uVar)
IF cPicture == Nil
   IF cType == "C"
	   cPicture := "@S"+Alltrim(Str(Len(uVar),4,0))
	ElseIF cType == "N"
	   cPicture := "999999999.99"
	ElseIF cType == "D"
	   cPicture := "99/99/9999"
	Else
		UserException("Invalid Type For Say/Get")
	Endif
Endif	                    
Return cPicture

Function VTROW()
Return _nL

Function VTCOL()
Return _nC                                         

Function VTInkey(nTime)
Local cByte, nX 
Local nByte := 0, lWait := .f.         

IF nTime != Nil .and. nTime == 0
  lWait := .t.
Endif
                    
IF !lWait      
   nX := IIF(nTime==Nil,0,nTime*1000)
   cByte := VtReadByte(nX,1,1)
   IF Len(cByte) > 0
      VTGetByte()
   Endif
Else
  cByte := VTGetByte()   
Endif

IF Len(cByte) > 0
   nByte := ASC(cByte)
   IF nByte == 27
      IF VtReadByte(0,1,1) == Chr(91)
         IF VtReadByte(0,2,1) == Chr(65)
            nByte := 5
            VtGetByte()
            VtGetByte()
         ElseIF VtReadByte(0,2,1) == Chr(67)
            nByte := 4
            VtGetByte()
            VtGetByte()
         ElseIF VtReadByte(0,2,1) == Chr(68)
            nByte := 19
            VtGetByte()
            VtGetByte()
         ElseIF VtReadByte(0,2,1) == Chr(66)
            nByte := 24
            VtGetByte()
            VtGetByte()
         Endif  
      Endif       
   Endif
Endif
If nByte # 0
  __cLastKey := Chr(nByte)
EndIf
If lDebugVt
   PROCESSMESSAGE()
EndIf           
VTMonitor()
Return nByte


Function VtClearBuffer()
Local c := "_VTCLEARBUFFER"
If !lDebugVt
   &(c)(,,)
Else
   cBufSimVt := ""   
EndIf   
__cIntBuffer:=''
Return Nil


Function VtClearVt100()
If !lDebugVt
	__cBufferVt100 := ""   
EndIf   
Return Nil

Function VtWriteVt100(cVar) // funcao de controle do get 
If !lDebugVt
	__cBufferVt100 +=cVar   
EndIf   
Return Nil

Function xxVTQOut(uVar)
Local aNew, ni
VtBegin()
VTCROUT(Chr(13))
VTCROUT(CHR(10))
_nL++
_nC:=0
IF _nL >= __aVtSize[1]
   _nL := __aVtSize[1]-1
Endif       
aNew := {}
For ni:= 2 to Len(__aScreen)
   AADD(aNew,__aScreen[ni])
Next
__aScreen := aClone(aNew)
AADD(__aScreen,Space(__aVtSize[2]))
VTSAY(_nL,_nC,cValToChar(uVar))
VTEnd()
VTMonitor()    
Return Nil


Function __VTShowInServer()
Local ni
For ni:= 1 to Len(__aScreen)
  ConOut(RTRIM(__aScreen[ni]))
Next
Return Nil                 


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o	 ³ VTaChoice³ Autor ³ Sandro                ³ Data ³ 15/12/00 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡„o ³ A VTaChoice para VT100 simula a Achoice do Clipper		     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ simulador VT100 		    								           ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function VTaChoice(nTop,nLeft,nBottom,nRight,aMenu, aLogicals, cFunct,nIniVetor,lNoTrim,lMsg,nIniW,lScroll)
Local nSelectDraw  := 1
Local nSelectOld   := nSelectDraw
Local nPIniaMenu   := 1 
Local aTela        :={}               
Local nLenWindow   := 0
Local nLenString   := 0
Local nKey         := 0          
Local nPosaMenu    := 1  
Local nModo        := 0 
Local nRetUser     := 2              
Local nPosMAnt     := 0
Local aLogicInterno:={}
Local nX:=0     
Local nQtdeNValid :=0
Local uLogic
Local nStart
Local lCanScroll
Private cBufferaCh := ''
VTInitialize()

//Setando parametros default
nTop     := If(nTop#NIL,nTop,0)
nLeft    := If(nLeft#NIL,nLeft,0)
nBottom  := If(nBottom#NIL,nBottom,__aVtSize[1]-1)
nRight   := If(nRight#NIL,nRight,__aVtSize[2]-2)
aLogicals:= If(aLogicals#NIL,aLogicals,{})                             
lNoTrim  := If(lNotrim#NIL,.t.,lNotrim)
lMsg     := If(lMsg#NIL,.t.,lMsg)  
lScroll  := If(lScroll#NIL,lScroll,.F.)
nIniW    := if(nIniW#NIL,nIniW,1)
              
nTop    := If(nTop > VTMaxRow(),0,nTop)
nLeft   := If(nLeft > VTMaxCol(),0,nLeft)
nBottom := If(nBottom > VTMaxRow()+1,VTMaxRow(),nBottom)  
nRight  := If(nRight > VTMaxCol()+1,VTMaxCol(),nRight)

//preparando o array interno com o controle de acesso ao item
aLogicInterno := array(len(aMENU))
For nX := 1 to Len(aLogicInterno)
   If nX <= Len(aLogicals)
      aLogicInterno[nX] := aLogicals[nX] 
   else               
      aLogicInterno[nX] := .t.
   EndIf   
Next
                    
nLenWindow := nBottom-nTop+1
nLenString := nRight-nLeft 
nIniVetor  := If(nIniVetor#NIL,nIniVetor-nIniW+1,1)
nIniVetor  := If(nIniVetor <=0,1,nIniVetor)
nPosAMenu  := nIniVetor

If  nIniVetor > nLenWindow 
   nPIniaMenu := nIniVetor-nSelectDraw+1
   If nPIniaMenu > (len(aMenu)-nLenWindow)
      nPIniaMenu := (len(aMenu)-nLenWindow)+1 
      nSelectDraw := nLenWindow-(len(aMenu)-nIniVetor)
      nSelectOld  := nSelectDraw
   EndIf  
ElseIf nIniVetor-nLenWindow <=  0
   nSelectDraw := nIniVetor
   nSelectOld  := nSelectDraw
   nPIniaMenu := 1
Endif   
For nX := 1 to nIniW-1                  
   If len(aLogicInterno) >= nX+nIniVetor-1
      uLogic :=aLogicInterno[nX+nIniVetor-1]
      If (Valtype(uLogic)== "C" .and.  &uLogic) .or.;
         (Valtype(uLogic)== "L" .and.  uLogic)
        cBufferaCh += chr(24)
      EndIF  
   EndIF
Next
VTAcessoAchoice(1,aLogicInterno,.F.) // verifica o acesso 
nPosMAnt := 0
nStart := 1

While .t.  
   nKey := 0       
   nModo:= 0         
   nRetUser := 2
   If nPosAMenu # nPosMAnt 
      aTela:=Aclone(VtLoadaMenu(aMenu,nLenWindow,nLenString,nPIniaMenu,lNoTrim))
      VtSayachoice(nTop,nLeft,aTela,nSelectDraw,nSelectOld,nLenString,lMsg,lScroll)
      nStart := 1
   EndIf     
   VtPos(VTRow(),VTMaxCol())
   nPosMAnt := nPosAMenu   
   IF len(cBufferaCh) >0
     nKey := asc(Left(cBufferaCh,1))
     cBufferaCh := Subs(cBufferaCh,2)
     __cLastKey := chr(nKey)
   Else  
     nKey := VTInkey(0)
   EndIf

	If VTModelo()<>"RF" .and. nKey == 44
	   VtkeyBoard(chr(1))
	   Loop
	EndIf

   nSelectOld := nSelectDraw   
   If nKey == 27
      nModo :=3
      nRetUser := 0   
   Elseif nKey == 13 // enter
      nModo := 3
      nRetUser := 1
   Elseif nKey == 5 .or. chr(nKey) $ '8MmAa'// Up   
      VTAcessoAchoice(nPosaMenu-1,aLogicInterno,.T.)             
      If nSelectDraw = 1
         If (nPIniaMenu) > 1            
            nPIniaMenu-- 
            nPosaMenu-- 
         ELSE
            nModo := 1   
         EndIf        
      Else                       
         nSelectDraw-- 
         nPosaMenu-- 
      EndIF   
   Elseif nKey == 24 .or.chr(nKey) $ '2NnBb' // down 
      VTAcessoAchoice(nPosaMenu+1,aLogicInterno,.F.)             
      If nSelectDraw = nLenWindow
         If (nPIniaMenu+nLenWindow) <= Len(aMenu)                
            nPIniaMenu++
            nPosaMenu++
         ELSE          
            nModo := 2
         EndIf        
      Else         
         If (nPosaMenu) < len(aMenu)
            nSelectDraw++
            nPosaMenu++  
         EndIf   
      EndIF   
   ElseIf nKey== 57 .or. nkey==55 .or. chr(nKey)$"79"  // tecla R ou r PgUp   
      If nPosaMenu-nLenWindow > 0
          nQtdeNValid:=0
	      For nX:= nPosaMenu-nLenWindow to nPosaMenu  
             uLogic :=aLogicInterno[nX]
             If (Valtype(uLogic)== "C" .and. ! &uLogic) .or. ;
                (Valtype(uLogic)== "L" .and. ! uLogic)
                nQtdeNValid++
             EndIf   
	      Next   
	      For nX:= 1 to (nLenWindow-1)-nQtdeNValid
	         cBufferaCh +=chr(5)
	      Next   
      Else                         
         nPIniaMenu:=1 
         nPosaMenu :=1 
         nSelectDraw:=1                                   
         VTAcessoAchoice(1,aLogicInterno,.F.) 
         nModo := 1   
      EndIf
   ElseIf nKey== 49 .or. nkey==51 .or. chr(nKey)$"13" // tecla C ou c  PgDow
      If nPosaMenu+nLenWindow <= len(aLogicInterno)
         nQtdeNValid :=0      
         For nX:= nPosaMenu to nPosaMenu+nLenWindow
            uLogic :=aLogicInterno[nX]
            If (Valtype(uLogic)== "C" .and. ! &uLogic) .or. ;
               (Valtype(uLogic)== "L" .and. ! uLogic)
               nQtdeNValid++
            EndIf   
         Next
         For nX:= 1 to (nLenWindow-1)-nQtdeNValid
            cBufferaCh +=chr(24)
         Next  
      Else
         /* 
         nPIniaMenu:=Len(aMenu)-nLenWindow+1 
         nPosaMenu :=Len(aMenu) 
         nSelectDraw:=nLenWindow                                   
         VTAcessoAchoice(Len(aMenu),aLogicInterno,.T.) 
         nModo := 2
         */
      EndIf
   ElseIf lScroll .and. (nKey == 4 .or. nKey == 19 .or. Chr(nKey) $ "46")	//esquerda ou direita
		If nKey == 4 .or. Chr(nKey) =="6"
			If (Len(aTela[nSelectDraw]) - nStart) >= nLenString
				nStart++
				lCanScroll := .T.
			Else
				lCanScroll := .F.
			EndIf
		Else
			If nStart > 1
				nStart--
				lCanScroll := .T.
			Else
				lCanScroll := .F.
			EndIf 
		EndIf
		If lCanScroll
			VtSayachoice(nTop,nLeft,aTela,nSelectDraw,nSelectOld,nLenString,lMsg,lScroll,nStart)
		EndIf
   Endif
   If ValType(cFunct)=="C" 
  	  nRetUser:= &cFunct.(nModo,nPosaMenu,nSelectDraw-1)
   EndIf	  
   If nRetUser == 0  // Esc
      nPosaMenu := 0
      exit
   Elseif nRetUser == 1 // Enter
      Exit
   EndIf
End   
Return nPosaMenu
// funcao auxiliar do VTaChoice
Static Function VtLoadaMenu(aMenu,nLenWindow,nLenString,nPosIni,lNoTrim)
Local aVetor:={}   
Local cMenu
Local n

For n:= 1 to nLenWindow
   If nPosIni > len(aMenu)
      aadd(aVetor,Padr('',nLenString))
   Else 
      cMenu := aMenu[nPosIni++]
      If lNoTrim
         aadd(aVetor,cMenu)
      Else
         aadd(aVetor,Trim(cMenu))
      EndIf   
   Endif   
Next
Return aVetor
// funcao auxiliar do VTaChoice
Static Function VtSayAchoice(nTop,nLeft,aTela,nSelect,nSelectOld,nLen,lMsg,lScroll,nStart)
Local nX :=0                                  
Local nUl:=0,nUC:=0
Local cSay
If lScroll .and. (nStart <> NIL)
	VTSAY(nTop+nSelect-1,nLeft,Subs(aTela[nSelect],nStart,nLen))
	VTPOS(nTop+nSelect-1,nLeft)
ElseIf nSelect ==nSelectOld      
   For nX:= 1 to Len(aTela)                
      cSay := Padr(If(Len(aTela[nX]) > nLen,Subs(aTela[nX],1,nLen),aTela[nX]),nLen)
      If nSelect == nX
         VtReverso(.t.) 
         If VtMaxRow()==1
            cSay := Left(cSay,len(cSay)-1)+"<"
         EndIf
         VtSay(nTop+nX-1,nLeft,cSay)
         VtReverso(.f.)          
         nUl:=nTop+nX-1
         nUc:=nLeft
      Else
         VTSAY(nTop+nX-1,nLeft,cSay)
      EndIF   
   Next
   VTPOS(nUl,nUc)
Else
   VtReverso(.f.) 
	cSay := Padr(If(Len(aTela[nSelectOld]) > nLen,Subs(aTela[nSelectOld],1,nLen),aTela[nSelectOld]),nLen)
   VTSAY(nTop+nSelectOld-1,nLeft,cSay)
	cSay := Padr(If(Len(aTela[nSelect])>nLen,Subs(aTela[nSelect],1,nLen),aTela[nSelect]),nLen)
   VtReverso(.t.) 
   If VtMaxRow()==1
      cSay := Left(cSay,len(cSay)-1)+"<"
   EndIf
	VTSAY(nTop+nSelect-1,nLeft,cSay)
   VtReverso(.f.) 
   VTPOS(nTop+nSelect-1,nLeft) 
EndIf   
Return                                                   

// funcao auxiliar do VTaChoice
static Function VTAcessoAchoice(nPos,aLogic,lUp)
Local uLogic 
If nPos > len(aLogic)                      
   nPos := len(aLogic)   
   uLogic :=aLogic[nPos]
   If (Valtype(uLogic)== "C" .and. ! &uLogic) .or.;
      (Valtype(uLogic)== "L" .and. ! uLogic)
      cBufferaCh+=chr(5)  //seta para cima
   EndIF   
ElseIf  nPos < 1      
   nPos := 1          
   uLogic :=aLogic[nPos]
   If (Valtype(uLogic)== "C" .and. ! &uLogic) .or. ;
      (Valtype(uLogic)== "L" .and. ! uLogic)
      cBufferaCh +=chr(24) // seta par abaixo
   EndIf   
Else
   uLogic :=aLogic[nPos]
   If (Valtype(uLogic)== "C" .and. ! &uLogic) .or. ;
      (Valtype(uLogic)== "L" .and. ! uLogic)
      If lUp                              
         cBufferaCh+=chr(5)  //seta para cima      
      else 
         cBufferaCh+=chr(24)  //seta para baixo
      endif   
   EndIf                   
EndIf   
Return

Function VTAlert(cMsg,cCaption,lCenter,nSleep,nBeep)
Local i
Local nLen
Local aScr
Local cLine
Local aMsg := {}
Local nMaxCol := VTMaxCol()
Local nPadc
Local nRow1
Local nRow2                                        
Local lTerminal := (VTMaxRow()==1)                
Local nSec

If nBeep#NIL
   VTBeep(nBeep)
EndIf

//Inicializa ambiente
VTInitialize()
If  ! lTerminal
	//centraliza msg
	VTSetCenter()
	
	nRow1 := __aVTAlert[1]
	nRow2 := __aVTAlert[2]
	nPadc := __aVTAlert[3]
	
	lCenter := If(lCenter == NIL,.F.,lCenter)
Else                  
   nRow1 := 0
   nRow2 := VtMaxRow()
	nPadc := VtMaxCol()-1
	lCenter:=.f.
EndIf
cMsg := If(cMsg == NIL,"",cMsg)
cCaption := If(cCaption == NIL,Left(cVersao,8),cCaption)
cCaption := Padc(Padc(cCaption,nPadc),nMaxCol)

aScr := VTSave()
If  lTerminal 
   cMsg:= Strtran(cMsg,chr(13)," ")
   cMsg:= Strtran(cMsg,chr(10),"")   
   cMsg:= '['+Alltrim(cCaption)+'] '+cMsg
   lCenter:= .f.
Else
	Aadd(aMsg,cCaption)
	//Aadd(aMsg,"") // foi o sandro que tirou para ver como vai ficar
EndIf	

nLen := MlCount(cMsg,nPadc+1)
//lCenter := If(nLen == 1,.T.,lCenter)
For i := 1 To nLen
	cLine := MemoLine(cMsg,nPadc+1,i)
	If lCenter
		cLine := AllTrim(cLine)
		cLine := Padc(cLine,nPadc+1)
	EndIf
	cLine := Padc(cLine,nMaxCol+1)
	Aadd(aMsg,cLine)
Next

VTClear()
If nSleep#NIL
   VTKeyboard(chr(13))
EndIf
VTaChoice(nRow1,0,nRow2,VTMaxCol()+1,aMsg,,,,.T.,.T.)
If nSleep#NIL     
	nSec:= Seconds()+(nSleep/1000)
  	If nSec > 86399
     	Sleep(nSleep)
   Else
	   While nSec > Seconds()
			Sleep(10)
	 	end  
	EndIf
EndIf
VTRestore(,,,,aScr)
Return VTInkey()


Function VTMaxCol()
Return __aVtSize[2]-2

Function VTMaxRow()
Return __aVtSize[1]-1

Function VTAlertPos(nPos)
If nPos > 0 .and. nPos <= Len(__aVTAlert)
    Return __aVTAlert[nPos]
EndIf
Return 0

//-------------------------------------------------------------------------------------------------------
// Esta funcao eh executada como macro na funcao VTAchoice por isso ao compilar estah exibindo um warning
//-------------------------------------------------------------------------------------------------------
Static Function VTYesCtrl(nModo,nPos,nPosW)
If chr(VTLastKey()) $ 'NnYySs5' .or. VTLastkey() == 27
   Return 0
EndIf   
Return 2                      

Function VTSetCenter()
Local nRow1
Local nRow2

VTInitialize()

If __aVTAlert == NIL
	__aVTAlert := Array(3)
	
	nRow1 := Int(VTMaxRow()/2)
	nRow2 := Int(nRow1/2)
	__aVTAlert[1] := If(nRow1 < 8,0,nRow1 - nRow2)
	__aVTAlert[2] := If(nRow1 < 8,VTMaxRow(),nRow1 + nRow2)

	__aVTAlert[3] := Int(VTMaxCol()/2)
	__aVTAlert[3] := If(__aVTAlert[3] < VTMaxCol(),VTMaxCol(),__aVTAlert[3])
EndIf
Return __aVTAlert


//---------------------------------------------------------------------
Function VTaBrowse(nTop,nLeft,nBottom,nRight,aCab,aItens,aSize,cFunct,nIniVetor,cSeparador)
Local nSelectDraw  := 1
Local nSelectOld   := nSelectDraw
Local nPIniaMenu   := 1 
Local aTela        :={}               
Local nLenWindow   := 0
Local nLenString   := 0
Local nKey         := 0          
Local nPosaMenu    := 1  
Local nModo        := 0 
Local nRetUser     := 2              
Local nPosMAnt     := 0
Local nX:=0     
Local nCol:= 1      
Local nQtdCol:= 1
Local lMoveCol:=.f.           
Local lMT := VTModelo()<>"RF"                                                   
default cSeparador:="|"
//nIniVetor := 3

//Setando parametros default
nTop   := If(nTop#NIL,nTop,0)
nLeft  := If(nLeft#NIL,nLeft,0)
nBottom:= If(nBottom#NIL,nBottom,__aVtSize[1]-1)
nRight := If(nRight#NIL,nRight,__aVtSize[2]-2)       

nTop    := If(nTop > VTMaxRow(),0,nTop)
nLeft   := If(nLeft > VTMaxCol(),0,nLeft)
nBottom := If(nBottom > VTMaxRow(),VTMaxRow(),nBottom)  
nRight  := If(nRight > VTMaxCol(),VTMaxCol(),nRight)

nIniVetor:= If(nIniVetor#NIl,nIniVetor+If(lMT,1,2),3)
nLenWindow := nBottom-nTop+1
nLenString := nRight-nLeft 
nPosAMenu  := nIniVetor
If  nIniVetor > nLenWindow 
   nSelectDraw := nLenWindow 
   nSelectOld  := nSelectDraw
   nPIniaMenu  := nIniVetor-nLenWindow+1
ElseIf nIniVetor-nLenWindow <=  0
   nSelectDraw := nIniVetor
   nSelectOld  := nSelectDraw
   nPIniaMenu := 1
Endif   

nPosMAnt := 0     
While .t.  
   nKey := 0       
   nModo:= 0         
   nRetUser := 2
   If nPosAMenu # nPosMAnt .or. lMoveCol .or. __laBrwRefresh
      aTela:=Aclone(VtLoadaBrowse(aCab,aItens,aSize,nLenWindow,nLenString,nPIniaMenu,nCol,@nQtdCol,cSeparador))
      VtSayaBrowse(nTop,nLeft,aTela,nSelectDraw,nSelectOld,nLenString)
      lMoveCol:= .f.
		__laBrwRefresh:= .f.      
   EndIf     
   nPosMAnt := nPosAMenu    
   VtPos(VTRow(),VTMaxCol())
   nKey := VTInkey(0)
   nSelectOld := nSelectDraw   
   If nKey == 27
      nModo :=3
      nRetUser := 0   
   Elseif nKey == 13 // enter
      nModo := 3
      nRetUser := 1
   Elseif nKey == 5 .or. chr(nKey) $ '8MmAa'// Up   
      If nSelectDraw == If(lMT,2,3)
         If (nPIniaMenu) > 1 
            nPIniaMenu-- 
            nPosaMenu-- 
         ELSE
            nModo := 1   
         EndIf        
      Else                       
         nSelectDraw-- 
         nPosaMenu-- 
      EndIF   
   Elseif nKey == 24 .or.chr(nKey) $ '2NnBb' // down 
      If nSelectDraw == nLenWindow
         If (nPIniaMenu+nLenWindow) <= (Len(aItens)+If(lMT,1,2))                
            nPIniaMenu++
            nPosaMenu++
         ELSE          
            nModo := 2
         EndIf        
      Else         
         If (nPosaMenu) < (len(aItens)+If(lMT,1,2))
            nSelectDraw++
            nPosaMenu++  
         EndIf   
      EndIF                                       
   Elseif nKey ==  4 .or.chr(nKey) $ '6LlFf' //Direita
      If ! empty(aItens) .and. nCol < Len(aItens[1])
         lMoveCol:= .t.
         nCol++
      EndiF   
   Elseif nKey == 19 .or.chr(nKey) $ '4KkEe' //esquerda
      If nCol >1 
         lMoveCol:= .t.
         nCol--   
      EndiF   
   ElseIf nKey== 57 .or. nkey==55  // tecla 9 e 7 PgUp   
      For nX := 1 to nLenWindow-If(lMT,1,2)
         VtKeyboard(Chr(5))
      Next
   ElseIf nKey== 49 .or. nkey==51 // tecla 1 e 3 PgDow
      For nX := 1 to nLenWindow-If(lMT,1,2)
         VtKeyboard(Chr(24))
      next
   Endif
   If ValType(cFunct)=="C" 
  	  nRetUser:= &cFunct.(nModo,nPosaMenu-If(lMT,1,2),nSelectDraw-1)
   EndIf	  
   If nRetUser == 0  // Esc
      nPosaMenu := If(lMT,1,2)
      exit
   Elseif nRetUser == 1 // Enter
      Exit
   EndIf
End   
Return nPosaMenu-If(lMT,1,2)
// funcao auxiliar do VTABrowse

Static Function VtLoadaBrowse(aCab,aMenu,aSize,nLenWindow,nLenString,nPosIni,nCol,nQtdCol,cSeparador)
Local aVetor:={}   
Local sLinha:=''
Local nX,nLenLinha:=0
Local n               
Local uConteudo             
Local lMT := VTModelo()<>"RF"
DEFAULT cSeparador:="|"
//descubrir qtde de colunhas que cab
nLenLinha:=0                
nQtdCol:= 0
For nX := nCol to Len(aCab)   
    nQtdCol++
    If nLenLinha+aSize[nx]+1 > nLenString
       Exit
    EndIF    
    nLenLinha+=aSize[nx]+1
Next      
sLinha:=''
For nX := 1 to nQtdCol
     sLinha += Padr(aCab[nCol+nX-1],aSize[nCol+nX-1])     
     If nX < nQtdCol
        sLinha+=cSeparador
     EndIf
Next                    
aadd(aVetor,sLinha)      
If ! lMT
	sLinha:=''
	For nX := 1 to nQtdCol
	     sLinha += Repl('-',aSize[nCol+nX-1])     
	     If nX < nQtdCol
	        sLinha+=cSeparador
	     EndIf
	Next                    
	aadd(aVetor,sLinha)
EndIf	
For n:= 1 to nLenWindow-If(lMT,1,2)
   If nPosIni > len(aMenu)
      aadd(aVetor,Padr('',nLenString))
   Else          
      sLinha := ''
      For nX := 1 to nQtdCol
         uConteudo := aMenu[nPosIni,nCol+nX-1]
         
         If Valtype(uConteudo) =='C'         
            uConteudo:= Padr(uConteudo,aSize[nCol+nX-1])     
         ElseIf Valtype(uConteudo) =='N'
             uConteudo := Str(uConteudo) 
             uConteudo := Padl(AllTrim(uConteudo),aSize[nCol+nX-1])     
         ElseIf Valtype(uConteudo) =='D' 
             uConteudo := Padc(Dtoc(uConteudo),aSize[nCol+nX-1])     
         ElseIf Valtype(uConteudo) =='L' 
             uConteudo := if(uConteudo,'T','F')
         ElseIf Valtype(uConteudo) =='M'              
             uConteudo := 'MEMO'
         End
         sLinha +=uConteudo 
         If nX < nQtdCol
            sLinha+=cSeparador
         EndIf
      Next                    
      nPosIni++
      aadd(aVetor,Padr(sLinha,nLenString))
   Endif   
Next
Return aVetor
// funcao auxiliar do VTaChoice
Static Function VtSayaBrowse(nTop,nLeft,aTela,nSelect,nSelectOld,nLen)
Local nX :=0                                  
Local nUl:=0,nUC:=0                  
Local cSay
If nSelect ==nSelectOld     
   For nX:= 1 to Len(aTela)                
      If nSelect == nX
         VtReverso(.t.)            
         cSay := Padr(aTela[nX],nLen)
         If VtMaxRow()==1
            cSay := Left(cSay,len(cSay)-1)+"<"
         EndIf
         VTSAY(nTop+nX-1,nLeft,cSay)                 
         VtReverso(.f.)          
         nUl:=nTop+nX-1
         nUc:=nLeft
      Else
         VTSAY(nTop+nX-1,nLeft,Padr(aTela[nX],nLen))              
      EndIF   
   Next            
   VTPOS(nUl,nUc)
Else 
   VtReverso(.f.) 
   VTSAY(nTop+nSelectOld-1,nLeft,aTela[nSelectOld])
   VtReverso(.t.) 
   cSay := Padr(aTela[nSelect],nLen)
   If VtMaxRow()==1
      cSay := Left(cSay,len(cSay)-1)+"<"
   EndIf
	VTSAY(nTop+nSelect-1,nLeft,cSay)
   VtReverso(.f.) 
   VTPOS(nTop+nSelect-1,nLeft)
EndIf   
Return                                                   

Function VTaBrwRefresh()
	__laBrwRefresh:= .t.
Return 
///----Com DBbrose---------------------------
Function VTDbBrowse(nTop,nLeft,nBottom,nRight,cAlias,aCab,aFields,aSizeFields,cFunct,cTop,cBottom)
Local lMT := VTModelo()<>"RF"
Local nSelectDraw  := If(lMT,2,3)
Local nSelectOld   := nSelectDraw
Local aTela        := {}
Local nLenWindow   := 0
Local nLenString   := 0
Local nKey         := 0
Local nModo        := 0
Local nRetUser     := 2
Local nPosMAnt     := 0
Local nX           := 0
Local nCol         := 1
Local nQtdCol      := 1
Local lMoveCol     := .f.
Local aRecno       := {}
Local cConteudo,cTop1,cBottom1
dbSelectArea(cAlias)

//Setando parametros default
nTop   := If(nTop#NIL,nTop,0)
nLeft  := If(nLeft#NIL,nLeft,0)
nBottom:= If(nBottom#NIL,nBottom,__aVtSize[1]-1)
nRight := If(nRight#NIL,nRight,__aVtSize[2]-2)

nTop    := If(nTop > VTMaxRow(),0,nTop)
nLeft   := If(nLeft > VTMaxCol(),0,nLeft)
nBottom := If(nBottom > VTMaxRow(),VTMaxRow(),nBottom)
nRight  := If(nRight > VTMaxCol(),VTMaxCol(),nRight)+1

nLenWindow := nBottom-nTop+1
nLenString := nRight-nLeft

nPosMAnt := 0
lMoveCol:= .t.
While .t.
   nKey := 0
   nModo:= 0
   nRetUser := 2
   If lMoveCol .or. __lDbBrwRefresh
      aTela:=Aclone(VtLoadDbBrowse(aCab,aFields,aSizeFields,nLenWindow,nLenString,nCol,@nQtdCol,aRecno,cBottom))
      VtSayaBrowse(nTop,nLeft,aTela,nSelectDraw,nSelectOld,nLenString)
      lMoveCol:= .f.
      __lDbBrwRefresh := .f.
   EndIf
   VtPos(VTRow(),VTMaxCol())
   nKey := VTInkey(0)
   nSelectOld := nSelectDraw
   If nKey == 27
      nModo :=3
      nRetUser := 0
   Elseif nKey == 13 // enter
      nModo := 3
      nRetUser := 1
   Elseif nKey == 5 .or. chr(nKey) $ '8MmAa'// Up
      If nSelectDraw = If(lMT,2,3)
         Dbskip(-1)
         cConteudo := &(Indexkey())
         If Valtype(cTop)=='C'
            cTop1 := &cTop
         EndIf
         If bof()  .or. (Valtype(cTop1)=='C' .and. cTop1 > Left(cConteudo,len(cTop1)))
            IF ! Bof()
            Dbskip()
            EndIF
            lMoveCol:= .f.
            nModo := 1
         Else
            lMoveCol:= .t.
         EndIf
      Else
         lMoveCol:= .t.
         nSelectDraw--
      EndIf
   Elseif nKey == 24 .or.chr(nKey) $ '2NnBb' // down
      If nSelectDraw = nLenWindow
         nRecAnt:= recno()
         dbgoto(aRecno[nSelectDraw-If(lMT,1,2)])
         dbskip()
         cConteudo := &(Indexkey())
         If Valtype(cBottom)=='C'
            cBottom1 := &cBottom
         EndIf
         IF eof()  .or. (Valtype(cBottom1)=='C' .and.  cBottom1 < Left(cConteudo,len(cBottom1)))
             dbgoto(nRecAnt)
             lMoveCol:= .f.
             nModo := 2
         Else
            lMoveCol:= .t.
            dbgoto(nRecAnt)
            dbskip()
         EndIf
      Else
         If nSelectDraw <len(aTela)
            lMoveCol:= .t.
            nSelectDraw++
         Else
            nModo := 2
         EndIf
      EndIf
   Elseif nKey ==  4 .or.chr(nKey) $ '6LlFf' //Direita
      If nCol < len(aFields)
         lMoveCol:= .t.
         nCol++
      EndIf
   Elseif nKey == 19 .or.chr(nKey) $ '4KkEe' //esquerda
      If nCol >1 
         lMoveCol:= .t.
         nCol--
      EndIf
   ElseIf nKey== 57 .or. nkey==55  // tecla 9 e 7 PgUp
      For nX := 1 to nLenWindow-If(lMT,1,2)
         VtKeyboard(Chr(5))
      Next
   ElseIf nKey== 49 .or. nkey==51 // tecla 1 e 3 PgDow
      For nX := 1 to nLenWindow-If(lMT,1,2)
         VtKeyboard(Chr(24))
      next
   Endif
   If ValType(cFunct)=="C"
  	  nRetUser:= &cFunct.(nModo,aRecno[nSelectDraw-If(lMT,1,2)],nSelectDraw-1)
   EndIf
   If nRetUser == 0  // Esc
      exit
   Elseif nRetUser == 1 // Enter
      dbgoto(aRecno[nSelectDraw-If(lMT,1,2)])
      VTInkey()
      Exit
   EndIf
End   
Return recno()
// funcao auxiliar do VTABrowse
Static Function VtLoadDbBrowse(aCab,aFields,aSizeFields,nLenWindow,nLenString,nCol,nQtdCol,aRecno,cBottom)
Local aVetor:={}
Local sLinha:=''
Local nX,nLenLinha:=0
Local n
Local nRecno:= Recno()
Local uConteudo
Local npos
Local aFieldNames := ARRAY(FCOUNT())
Local aTypes := ARRAY(FCOUNT())
Local aSizes := ARRAY(FCOUNT())
Local aDecimals := ARRAY(FCOUNT())
Local cConteudo, cBottom1
Local nTamanho
Local lMT := VTModelo()<>"RF"


AFIELDS(aFieldNames, aTypes, aSizes, aDecimals)

//descubrir qtde de colunhas que cab
nLenLinha:=0
nQtdCol:= 0

For nX := nCol to Len(aFields)
    nQtdCol++
    If Valtype(aFields[nX])=='B'
       uConteudo := Eval(aFields[nX])
       If Valtype(uConteudo) ="N"
          nTamanho := 20
       ElseIf Valtype(uConteudo) ="D"
          nTamanho := 8
       Else
	       nTamanho := len(Eval(aFields[nX]))
       EndIf
       If nTamanho < len(aCab)
          nTamanho := len(aCab)
       EndIf
    Else
       nTamanho := aSizeFields[nX]
    EndIf
    If nLenLinha+nTamanho+1 > nLenString
       Exit
    EndIf
    nLenLinha+=nTamanho+1
Next
sLinha:=''
For nX := 1 to nQtdCol
    If Valtype(aFields[nX])=='B'
       uConteudo := Eval(aFields[nCol+nX-1])
       If Valtype(uConteudo) ="N"
          nTamanho := 20
       ElseIf Valtype(uConteudo) ="D"
          nTamanho := 8
       Else
	       nTamanho := len(Eval(aFields[nCol+nX-1]))
       EndIf
       If nTamanho < len(aCab)
          nTamanho := len(aCab)
       EndIf
    Else
       nTamanho := aSizeFields[nCol+nX-1]
    EndIf
    sLinha += Padr(aCab[nCol+nX-1],nTamanho)
    If nX < nQtdCol
       sLinha+='|'
    EndIf
Next
aadd(aVetor,sLinha)
If ! lMT
	sLinha:=''
	For nX := 1 to nQtdCol
	    If Valtype(aFields[nX])=='B'
       	 uConteudo := Eval(aFields[nCol+nX-1])
       	 If Valtype(uConteudo) ="N"
          	 nTamanho := 20
       	 ElseIf Valtype(uConteudo) ="D"
         	 nTamanho := 8
       	 Else
	       	 nTamanho := len(Eval(aFields[nCol+nX-1]))
       	 EndIf
	       If nTamanho < len(aCab)
	          nTamanho := len(aCab)
	       endIf
	    Else
	       nTamanho := aSizeFields[nCol+nX-1]
	    EndIf
	    sLinha += Repl('-',nTamanho)

	     If nX < nQtdCol
	        sLinha+='|'
	     EndIf
	Next
	aadd(aVetor,sLinha)
EndIf
aRecno:={}

For n:= 1 to nLenWindow-If(lMT,1,2)
      sLinha := ''
      For nX := 1 to nQtdCol
         If Valtype(aFields[nCol+nX-1])=='B'
       	 	uConteudo := Eval(aFields[nCol+nX-1])
       	 	If Valtype(uConteudo) ="N"
       	 		uConteudo := Str(Eval(aFields[nCol+nX-1]),20,4)
       	 	ElseIf Valtype(uConteudo) ="D"
       	 		uConteudo := Dtoc(Eval(aFields[nCol+nX-1]))
       	 	Else
	       		uConteudo := Eval(aFields[nCol+nX-1])
       	 	EndIf
            If len(uConteudo) < len(aCab)
               uConteudo := Padr(uConteudo,len(aCab))
            endIf
         Else
            uConteudo :=FieldGet(FieldPos(aFields[nCol+nX-1]))
            nPos := ASCAN(aFieldNames,aFields[nCol+nX-1])
            If aTypes[nPos] =='C'
               uConteudo:= Padr(uConteudo,aSizeFields[nCol+nX-1])
            ElseIf aTypes[nPos] =='N'
               uConteudo := Str(uConteudo,aSizes[nPos],aDecimals[npos])
               uConteudo := Padl(AllTrim(uConteudo),aSizeFields[nCol+nX-1])
            ElseIf Valtype(uConteudo) =='D'
               uConteudo := Padc(Dtoc(uConteudo),aSizeFields[nCol+nX-1])
            ElseIf Valtype(uConteudo) =='L'
               uConteudo := if(uConteudo,'T','F')
            ElseIf Valtype(uConteudo) =='M'
               uConteudo := 'MEMO'
            End
         EndIf
         sLinha +=uConteudo
         If nX < nQtdCol
            sLinha+='|'
         EndIf
      Next
      aadd(aVetor,Padr(sLinha,nLenString))
      aadd(aRecno,recno())
      dbSkip()
      cConteudo := &(Indexkey())
      If Valtype(cBottom)=='C'
         cBottom1 := &cBottom
      EndIf
      IF eof()  .or. (Valtype(cBottom1)=='C' .and.  cBottom1 < Left(cConteudo,len(cBottom1))) 
         exit
      endif
Next
dbgoto(nRecno)
Return aVetor
// funcao auxiliar do VTaChoice
//-------------------------------------------------------------------------------------------------------
// Esta funcao eh executada como macro na funcao VTAchoice por isso ao compilar estah exibindo um warning
//-------------------------------------------------------------------------------------------------------
Static Function VtSayDbBrowse(nTop,nLeft,aTela,nSelect,nSelectOld,nLen)
Local nX :=0
Local nUl:=0,nUC:=0
Local cSay
If nSelect ==nSelectOld
   For nX:= 1 to Len(aTela)
      If nSelect == nX
         VtReverso(.t.)
         cSay := Padr(aTela[nX],nLen)
         If VtMaxRow()==1
            cSay := Left(cSay,len(cSay)-1)+"<"
         EndIf
         VTSAY(nTop+nX-1,nLeft,cSay)
         VtReverso(.f.)
         nUl:=nTop+nX-1
         nUc:=nLeft
      Else
         VTSAY(nTop+nX-1,nLeft,Padr(aTela[nX],nLen))
      EndIf
   Next
   VTPOS(nUl,nUc)
Else
   VtReverso(.f.)
   VTSAY(nTop+nSelectOld-1,nLeft,aTela[nSelectOld])
   VtReverso(.t.)
   cSay := aTela[nSelect]
   If VtMaxRow()==1
       cSay := Left(cSay,len(cSay)-1)+"<"
   EndIf
	VTSAY(nTop+nSelect-1,nLeft,cSay)
   VtReverso(.f.)
   VTPOS(nTop+nSelect-1,nLeft)
EndIf
Return

Function VTDbBrwRefresh()
	__lDbBrwRefresh:= .t.
Return

Function VTBeep(nQtde)
Local nX
nQtde := if(nQtde#NIL,nQtde,1)
For nX := 1 to nQtde
	If !lDebugVt
		If VTModelo()=="RF"
			PutInBuffer(chr(7))
		Else 
			PutInBuffer(chr(27)+"[?24c"+Chr(27)+"[5i"+chr(4)+Chr(27)+"[4i")
			Sleep(100)
			PutInBuffer(chr(27)+"[?24c"+Chr(27)+"[5i"+chr(5)+Chr(27)+"[4i")
		EndIf
	EndIf
Next
return

Function VTLoadMsgMonit()
  VTMonitor()
Return

Static Function VTMonitor()
Local cMsg
If __NumVt # '' .and. File('VT'+__NumVT+'.MON') 
//   FT_SaveArr({__aScreen,__aReverso},'VT'+__NumVT+'.MON')
   VTScrToFile('VT'+__NumVT+'.MON')
ElseIf __NumVt # '' .and. File('VT'+__NumVT+'.MSG') 
   VTBeep(4)
   cMsg := MemoRead('VT'+__NumVT+'.MSG')
   FErase('VT'+__NumVT+'.MSG')
   VTAlert(cMsg,'Message <Enter>',,)
ElseIf __NumVt # '' .and. File('VT'+__NumVT+'.FIM')
   FErase('VT'+__NumVT+'.FIM')
   VTBeep()
	Final("Aviso","Desconectado pelo administrador")
EndIf
If ! __lRunTimer
	__lRunTimer:= .t. 
	VtVerTime()
	__lRunTimer:= .f.
EndIf
Return

Function VTConnect()
Local aDir
Local nX		:=0
Local nNovoId	:=1
Local cArquivo
Local nHTemp
Local lMayIUseDisk

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Verifica se o servidor de licensas esta ativado para    ³
//³usar o LockByName. Lembrando que neste momento o ambien-³
//³ainda nao foi aberto nao selecionando a empresa corrente³
//³.Nos demais pontos o 4o Parametro do LockByName nao eh  ³
//³passado para se ter o controle real de permissao de aces³
//³so a rotina.                                            ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
lMayIUseDisk := ( LS_GETTOTAL(1)< 0 )

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Verifica se esta locado por outro coletor e efetua teste³
//³100 vezes, se nao conseguir mesmo assim efetua UnLock   ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
While !LockByName("vtall.sem",.F.,.F.,lMayIUseDisk )
	Sleep(50)
	nX++
	If nX > 100
		Exit
	EndIf
End 
UnLockByName("vtall.sem",.F.,.F.,lMayIUseDisk )

aDir := Directory('VT*.SEM')
For nX := 1 to len(aDir)
   nHTemp := FOpen(aDir[nX,1],16)
   If nHTemp > 0
       FClose(nHTemp)
	   FErase(aDir[nX,1])
	EndIf
Next
aDir := Directory('VT*.SEM')      

While .t.
    cArquivo := 'VT'+StrZero(nNovoID,3)+'.SEM'
    If Ascan(aDir,{|x| x[1] == cArquivo} )==0
       __NumVT := StrZero(nNovoID,3)
       __HSemTer := MSFCreate(cArquivo)
       FWrite( __HSemTer, __NumVT+cUserName+Dtos(date())+time()+StrZero(VTMaxRow(),3)+StrZero(VTMaxCol(),3))
       Fclose(__HSemTer)
       __HSemTer:=FOpen(cArquivo,2)
       Exit
    EndIf
    nNovoID++
End
Return


Function VTAtuSem(cPrgInicial,cRotina)
Local cLinha    := Memoread('VT'+VTNumRF()+".sem")
Local cArquivo  := 'VT'+VTNumRF()+".sem"
Local nVezes	:= 0
Local lLock		:= .T.
Local lMayIUseDisk := ( LS_GETTOTAL(1)< 0 )

cPrgInicial := Left(cPrgInicial+" ",8)

//Fechou o semaforo para atualizacao
While !LockByName("vtall.sem",.F.,.F.,lMayIUseDisk )
	nVezes++
	Sleep(50)
	If nVezes > 100
		UnLockByName("vtall.sem",.F.,.F.,lMayIUseDisk)
		lLock := .F.
		Exit
	EndIf
End

cLinha := Left(cLinha,50)+cPrgInicial+cRotina
Fclose(__HSemTer)
MemoWrite(cArquivo,cLinha)
__HSemTer:=FOpen(cArquivo,2)

//Abro o semaforo somente se o lock foi realizado com sucesso.
If lLock
	UnLockByName("vtall.sem",.F.,.F.,lMayIUseDisk )
EndIf
Return


Function VTDisConnect()
FClose(__HSemTer)
FErase('VT'+__NumVT+'.SEM' )
__NumVT:=''
Return


Function VtDebug()
Local lAtvEnable := .T.
Local cNomeProg
Local oEnter
Local cCar
Local bBlock
Local oUp,oDown
Local cIniFile := GetADV97()
Local nI,nJ
Local nLin := 40
Local nCol := 3
Local aTitles
Local aPages
Local oFolder

lDebugVt := .t.

cNomeProg := GetPvProfString( "TELNET", "MAIN" , "SIGAACD", cIniFile )

If !("(" $ cNomeProg)
	cNomeProg+="()"
EndIf

oFontDeb  := TFont():New( "Mono AS", 16, 24, .F.,.T.,,,,,,,,,,, )
DEFINE FONT oFontDeb2 NAME "Mono AS" SIZE 16,24 UNDERLINE BOLD

DEFINE MSDIALOG oDlgDebVt FROM 0,0 TO 480,800 Pixel TITLE OemToAnsi("Simulador VT100")
oDlgDebVt:lEscClose := .F.

TButton():New( 010, 005, "Ativar",		oDlgDebVt, {|| (lAtvEnable := .F.,oEnter:SetFocus(),&cNomeProg)}, 38, 11,,, .F., .T., .F.,, .F., {|| lAtvEnable},, .F. )
TButton():New( 010, 065, "Desativar",	oDlgDebVt, {|| (lExitVT := .T.)},			38, 11,,, .F., .T., .F.,, .F., {|| !lAtvEnable},, .F. )
TButton():New( 010, 160, "CapsLock",	oDlgDebVt, {|| (lCapsLock := !lCapsLock)},	40, 10,,, .F., .T., .F.,, .F.,,, .F. )
TButton():New( 010, 220, "Espaco",		oDlgDebVt, {|| (VtTec(Space(01),oEnter))},	40, 10,,, .F., .T., .F.,, .F.,,, .F. )
TButton():New( 003, 300, "*",			oDlgDebVt, {|| (VtTec(Chr(05),oEnter))},	10, 10,,, .F., .T., .F.,, .F.,,, .F. )
TButton():New( 010, 280, "*",			oDlgDebVt, {|| (VtTec(Chr(19),oEnter))},	10, 10,,, .F., .T., .F.,, .F.,,, .F. )
TButton():New( 010, 320, "*",			oDlgDebVt, {|| (VtTec(Chr(04),oEnter))},	10, 10,,, .F., .T., .F.,, .F.,,, .F. )
TButton():New( 017, 300, "*",			oDlgDebVt, {|| (VtTec(Chr(24),oEnter))},	10, 10,,, .F., .T., .F.,, .F.,,, .F. )

aTitles := {"Saida Paralela","Saida Serial"}
aPages  := {"Saida Paralela","Saida Serial"}
oFolder := TFolder():New(180,0,aTitles,aPages,oDlgDebVT,,,,.t.,.F.,400,60)

@ 1,1 GET oMemoPar  VAR cMemoPar MEMO SIZE 396,46 OF oFolder:aDialogs[1] PIXEL FONT (TFont():New( "Courier New", 10, 26, .F.,.T.,,,,,,,,,,, ) )
oMemoPar:lReadOnly := .T.

@ 1,1 GET oMemoSer  VAR cMemoSer MEMO SIZE 396,46 OF oFolder:aDialogs[2] PIXEL FONT (TFont():New( "Courier New", 10, 26, .F.,.T.,,,,,,,,,,, ) )
oMemoSer:lReadOnly := .T.


aSayVt := Array(8,40,2)
For nI := 1 to 8
	nCol := 3
	For nJ := 1 to 40
		aSayVt[nI,nJ,2] := " "
		bBlock := &("{||aSayVt["+Str(nI,4)+","+Str(nJ,4)+",2]   }")
		aSayVt[nI,nJ,1] := TSay():New( nLin, nCol, bBlock,,, oFontDeb, .F., .F., .F., .T.,,, 15, 17, .F., .F., .F., .F., .F. )
		nCol+=10
	Next
	nLin+=16
Next

oUp    := TButton():New( 065, 1205, "UP", oDlgDebVt, , 38, 11,,, .F., .T., .F.,, .F.,,, .F. )
oUp:bGotFocus := {|| VtTec(Chr(05),oEnter)}
oEnter := TButton():New( 065, 1205, "ENTER", oDlgDebVt, {|| VtTec(Chr(13)+Chr(10),oEnter)}, 38, 11,,, .F., .T., .F.,, .F.,,, .F. )
oDown  := TButton():New( 065, 1205, "DOWN", oDlgDebVt, , 38, 11,,, .F., .T., .F.,, .F.,,, .F. )
oDown:bGotFocus := {|| VtTec(Chr(24),oEnter)}
TButton():New( 095, 1205, "&"+Chr(27)+"ESC", oDlgDebVt, {|| VtTec(Chr(27),oEnter)}, 38, 11,,, .F., .T., .F.,, .F.,,, .F. )
TButton():New( 125, 1205, "&"+Chr(08)+"BACKSPACE", oDlgDebVt, {|| VtTec(Chr(08),oEnter)}, 38, 11,,, .F., .T., .F.,, .F.,,, .F. )

For nI := 0 to 9
	cCar := Str(nI,1)
	bBlock := &("{||VtTec('"+cCar+"',oEnter)}")
	TButton():New( 135+(nI*10), 1205, "&"+cCar, oDlgDebVt, bBlock, 38, 11,,, .F., .T., .F.,, .F.,,, .F. )
Next
//  -- Caracteres Maiusc.: A - Z
For nI := 65 to 90
	cCar := Chr(nI)
	bBlock := &("{||VtTec('"+cCar+"',oEnter)}")
	TButton():New( 135+(nI*100), 1205, "&"+cCar, oDlgDebVt, bBlock, 38, 11,,, .F., .T., .F.,, .F.,,, .F. )
Next
/*  -- Caracteres Minusc.: a - z
For nI := 97 to 122
	cCar := Chr(nI)
	bBlock := &("{||VtTec('"+cCar+"',oEnter)}")
	TButton():New( 135+(nI*100), 1205, "&"+cCar, oDlgDebVt, bBlock, 38, 11,,, .F., .T., .F.,, .F.,,, .F. )
Next   
*/
For nI := 1 to 25
	cCar := Chr(nI)
	bBlock := &("{||VtTec('"+cCar+"',oEnter)}")
	TButton():New( 135+(nI*100), 1205, "&"+cCar, oDlgDebVt, bBlock, 38, 11,,, .F., .T., .F.,, .F.,,, .F. )
Next

//Tratativa para CTRL-X:
TButton():New( 010, 350,			"CTRL-X",	oDlgDebVt, {|| (VtTec('CTRLX',oEnter))}, 40, 10,,, .F., .T., .F.,, .F.,,, .F. )
TButton():New( 135+(nI*100), 1205,	"&.",		oDlgDebVt, {|| (VtTec(Chr(46),oEnter))}, 10, 10,,, .F., .T., .F.,, .F.,,, .F. )


ACTIVATE MSDIALOG oDlgDebVt CENTERED

Return .t.


Function VtAtuDeb()
Local nI,nJ
Local aOldSay := {,,}
Local lProcMess := .F.
For nI:= 1 to Len(__aScreen)
	If nI > Len(aSayVt)
		Exit
	EndIf
	For nJ := 1 to Len(__aScreen[nI])
		If nJ > Len(aSayVt[nI])
			Exit
		EndIf
		aOldSay[1] := aSayVt[nI,nJ,2]
		aOldSay[2] := aSayVt[nI,nJ,1]:NCLRTEXT
		aSayVt[nI,nJ,2] := SubStr(__aScreen[nI],nJ,1)
		If SubStr(__aReverso[nI],nJ,1) == "0"
			aSayVt[nI,nJ,1]:NCLRTEXT := CLR_BLACK
			aSayVt[nI,nJ,1]:OFONT    := oFontDeb
		Else
			aSayVt[nI,nJ,1]:NCLRTEXT := CLR_HRED //WHITE
			aSayVt[nI,nJ,1]:OFONT    := oFontDeb2
		EndIf
		If aSayVt[nI,nJ,2] # aOldSay[1] .or. aOldSay[2] # aSayVt[nI,nJ,1]:NCLRTEXT  // somente faz o refresh quando necessario
			aSayVt[nI,nJ,1]:Refresh()
			lProcMess := .T.
		EndIf
	Next
Next
//sleep(10)
If lProcMess
	PROCESSMESSAGE()
EndIf
Return .t.

Function VtTec(cGet,oGet)
If cGet == Chr(05)
	cGet := Chr(27)+Chr(91)+Chr(65)
ElseIf cGet == Chr(04)
	cGet := Chr(27)+Chr(91)+Chr(67)
ElseIf cGet == Chr(19)
	cGet := Chr(27)+Chr(91)+Chr(68)
ElseIf cGet == Chr(24)
	cGet := Chr(27)+Chr(91)+Chr(66)
ElseIf cGet == 'CTRLX'
	cGet := Chr(24)
ElseIf !lCapsLock .And. (cGet >= chr(65) .And. cGet <= chr(90))
	cGet := Lower(cGet)
EndIf
cBufSimVt+=cGet
oGet:SetFocus()
Return .f.

Function VtReverso(lRev)
local lRevAnt := __IsReverso
lRev := If(lRev==NIL,.f.,lRev)
If lRev
	If ! __IsReverso
		__IsReverso:= .t.
		VTCROUT(chr(27)+"[7m")
	EndIf
Else
	If  __IsReverso
		__IsReverso:= .f.
		VTCROUT(chr(27)+"[0m")
	EndIf
EndIf
Return lRevAnt

Function VTNumRF()
Return __NumVT

Function VTGetRefresh(cVar)
Local nLin,nCol,cPict,uVar
Local nTamArea :=0
Local nPos     := 0
If nInRead <=0
	Return
EndIf   
nPos := ascan(aVtList[nInRead],{|x| Alltrim(Upper(x[2])) == Alltrim(Upper(cVar))})
If nPos == 0
	Return
EndIf
nLin    := aVtList[nInRead,nPos,3]
nCol    := aVtList[nInRead,nPos,4]
cPict   := eval(aVtList[nInRead,nPos,6] )
uVar    := eval(aVtList[nInRead,nPos,9] )
nTamArea:= (VtmaxCol()-nCol)
If ValType(uVar)=="C" .AND. Len(uVar) > nTamArea
	VTSay(nLin,nCol,Left(uVar,nTamArea),cPict)
else
	VTSay(nLin,nCol,uvar,cPict)
EndIf
Return

Function VTScrToFile(cArq,aTela)
Local cConteudo:=''
Local nX
Local nH
Local nTamC
DEFAULT aTela := {__aScreen,__aReverso}
If len(aTela[1]) == 0
	nTamC:= 0
Else
	nTamC:= LEN(aTela[1,1])
EndIf
cConteudo := STR(LEN(aTela[1]),3)+STR(nTamC,3)
For nX := 1 to len(aTela[1])
	cConteudo+=aTela[1,nX]+aTela[2,nX]
Next
While ( nH:=FCreate(cArq,2) ) == -1
	Sleep(100)
EndDo
FWrite(nH,cConteudo,len(cConteudo))
FClose(nH)
Return

Function VTFileToScr(cArq)
Local nH,nLen,nX
Local cConteudo
Local nTamL,nTamC
Local aScreen:={},aReverso:={}
While (nH:= FOpen(cArq) )==-1
	If ! File(cArq)
		Return {}
	EndIf
	Sleep(100)
End
nLen := Fseek(nH,0,2)
Fseek(nH,0,0)
cConteudo := Space(nLen)
FRead(nH,@cConteudo,nLen)
Fclose(nH)
nTamL := Val(Subs(cConteudo,1,3))
nTamC :=Val(Subs(cConteudo,4,3))
cConteudo := Subs(cConteudo,7)
For nX:= 1 to nTamL
	aadd(aScreen,Subs(cConteudo,1,nTamC))
	cConteudo := Subs(cConteudo,nTamC+1)
	aadd(aReverso,Subs(cConteudo,1,nTamC))
	cConteudo := Subs(cConteudo,nTamC+1)
Next
Return {aScreen,aReverso}


Function VTImp(cStr)
Local c:="_VTOUT"
If !lDebugVt
	&(c)(Chr(27)+"[5i"+cSTR+Chr(27)+"[4i",)
Else
	If cDefPrint=="P"
		cMemoPar+=cSTR
		oMemoPar:Refresh()
	ElseIf cDefPrint=="S"
		cMemoSer+=cSTR
		oMemoSer:Refresh()
	EndIf
EndIf
Return

Function VTImpDef(cModo)
Local c:="_VTOUT"
If !lDebugVt
	&(c)(Chr(27)+"[?24"+If(cModo=="S","h","l"),)
Else
	cDefPrint	:=cModo
	If cDefPrint=="P"
		cMemoPar:=""
		oMemoPar:Refresh()
	ElseIf cDefPrint=="S"
		cMemoSer:=""
		oMemoSer:Refresh()
	EndIf
EndIf
Return


Function VTAddTimer(bBloco,nIntervalo)
Local nPos:= 0
If bBloco==NIL .or. nIntervalo==NIL
   Return -1
EndIf
__nIdTimer++
nPos := Ascan(__aTimer,{|x| x[1]==0})
If nPos == 0
	aadd(__aTimer,{__nIdTimer,bBloco,nIntervalo,Seconds()*1000,.t.})
Else
	__aTimer[nPos] := {__nIdTimer,bBloco,nIntervalo,Seconds()*1000,.t.}
EndIf
Return __nIdTimer

Function VtActiveTimer(nId,lActive)
Local nPos:= 0
nPos := Ascan(__aTimer,{|x| x[1]==nId})
If nId==NIL .or. nPos == 0
	Return NIL
EndIf
If lActive ==NIL
	lActive := __aTimer[nPos,5]
EndIf
__aTimer[nPos,5]:= lActive
Return lActive

Function VTdelTimer(nId)
Local nPos:= 0
nPos := Ascan(__aTimer,{|x| x[1]==nId})
If nId==NIL .or. nPos == 0
	Return NIL
EndIf
__aTimer[nPos] := {0,{|| .t. },0,0,.f.}
Return

Static Function VTVerTime()
Local nPos
Local nMilSec:= Seconds()*1000

For nPos := 1 to Len(__aTimer)
	If __aTimer[nPos,1] == 0 .or. ! __aTimer[nPos,5]
		Loop
	EndIf
	If __aTimer[nPos,4] > nMilSec
		__aTimer[nPos,4] :=__aTimer[nPos,4]-(86399*1000)
	EndIf

   If __aTimer[nPos,4]+__aTimer[nPos,3] <= nMilSec
		Eval(__aTimer[nPos,2])
		__aTimer[nPos,4] := nMilSec
	EndIf
Next
Return


Function VTModelo()
Local cRet
If VtMaxRow() == 1
	If VtMaxCol() > 20
		cRet:= "MT44"
	Else
		cRet:= "MT16"
	EndIf
Else 
	cRet:="RF"
EndIf
Return cRet
/*
 Esta funcao define como sera o preenchimento para identificar o get branco,ponto etc. 
 default 
 branco VT
 _ para microterminal
 
*/
Function VTFillGet(cCar)
If cCar<> NIL
	__FillGet:= cCar
EndIf
Return __FillGet
