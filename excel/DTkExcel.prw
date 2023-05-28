#include 'protheus.ch'
#include 'fileio.ch'

User Function DTkExcel(cAlias, cArqXlS)
    Private lAbortPrint := .F.

    If Select(cAlias) == 0
        Return 
    EndIf 

    Processa({|| GeraExcel(cAlias, cArqXlS) },,, .T.) 

    If lAbortPrint
    
        MsgAlert("Geração de planilha Excel Interrompida!")
        MsgAlert("Planilha Excel com conteudo parcial!!!!")
    
    Else
    
        MsgAlert("Geração de planilha Excel concluida!")
    
    EndIf 
    
    ShellExecute("open", cArqXLS, "", "", 1)
    
Return 

Static Function GeraExcel(cAlias, cArqXLS)
    Local oDBF
    Local cDirXls := ""
    Local cNomXlS := ""
    Local cNomTmp := ""
    Local np      := 0
    Local cTmpDbf := "\TIDBF\"

    nP := Rat("\", cArqXlS) 
    If nP > 0
        cDirXls := Left(cArqXlS, nP)
        cNomXls := Subs(cArqXlS, nP + 1)
    EndIf 
    // Trata os caminho e nome de arquivo no Server
    If ! ExistDir(cTmpDbf)
        MakeDir(cTmpDbf)
    EndIf 
    cNomTmp := "TMP" + FWTimeStamp() + ".xls"

    cFile  := cTmpDbf + cNomTmp
    If File(cFile)
        FErase(cFile)
    EndIf 
    ProcRegua(1)
    IncProc("Gerando arquivo Excel no servidor...")
    ProcessMessage()

    oDBF:= TIDBF():New(cFile)
    oDBF:CreateFrom(cAlias, .t.)
    oDBF:Close()
    FreeObj(oDBF)

    IncProc("Tranferindo arquivo Excel para maquina local...")
    ProcessMessage()

    If CpyS2T(cFile, cDirXls)
        Ferase(cFile)
    EndIf
    If FRename(cDirXls + cNomTmp,  cDirXls + cNomXlS) = -1
        MsgAlert("Não foi possivel renomear o arquivo " + cDirXls + cNomTmp )
    EndIf 

Return 




// Pseudo-comando para trabalhar com OFFSET de Base 0 em string AdvPL 
// Recebe STring, Offset Base 0 e Tamanho do bloco 
#xtranslate DBF_OFFSET(<cBuffer>,<nOffset>,<nSize>) => Substr(<cBuffer>,<nOffset>+1,<nSize>)

CLASS TIDBF FROM TIISAM

  DATA cDataFile			// Nome do arquivo de dados
  DATA cMemoFile			// Nome do arquivo memo (DBT/FPT) 

  DATA cDBFType				// Identificador hexadecimal do tipo do DBF 
  DATA dLastUpd				// Data registrada dentro do arquivo como ultimo UPDATE 
  DATA nRecLength			// Tamanho de cada registro 
  DATA nDataPos 			// Offset de inicio dos dados 
  DATA lHasMemo				// Tabela possui campo MEMO ?
  DATA nMemoType            // Tipo de campo MEMO da RDD ( 1 = DBT, 2 = FPT ) 
  DATA cMemoExt             // Identificador (extensao) do tipo do campo MEMO
  DATA lExclusive           // Arquivo aberto em modo exclusivo ?
  DATA lUpdPend             // Flag indicando update pendente 
  DATA lNewRecord           // Flag indicando a inserção de um registro
  DATA lDeleted				// Indicador de registro corrente deletado (marcado para deleção ) 
  DATA lSetDeleted          // Filtro de registros deletados ativo 

  DATA nHData				// Handler do arquivo de dados
  DATA oMemoFile			// Objeto para lidar com campo Memo 
    	
  // ========================= Metodos de uso público da classe

  METHOD NEW()    			// Construtor 
  METHOD OPEN()				// Abertura da tabela 
  METHOD CLOSE()			// Fecha a tabela 
  METHOD EXISTS()           // Verifica se a tabela existe 
  METHOD CREATE()           // Cria a tabela no disco 
  METHOD DROP()             // Apaga a tabela do disco 

  METHOD GetFileType()      // Tipo do arquivo ("DBF")

  METHOD GetDBType()		// REtorna identificador hexadecimal do tipo da tabela 
  METHOD GetDBTypeStr() 	// Retorna string identificando o tipo da tabela 
  METHOD GetMemoType()      // Tipo do MEMO usado, 1 = DBT , 2 = FPT

  METHOD FieldGet( nPos )   // Recupera o conteudo da coluna informada do registro atual 
  METHOD FieldPut( nPos )   // Faz update em uma coluna do registro atual 
  METHOD FileName()         // Retorna nome do arquivo aberto 
  METHOD Recno()			// Retorna o numero do registro (RECNO) posicionado 
  METHOD Deleted()			// REtorna .T. caso o registro atual esteja DELETADO ( Marcado para deleção ) 
  METHOD SetDeleted()       // Liga ou desliga filtro de registros deletados
  
  METHOD Insert()           // Insere um registro em branco no final da tabela
  METHOD Update()           // Atualiza o registro atual na tabela 

  METHOD Header() 			// Retorna tamanho em Bytes do Header da Tabela
  METHOD FileSize()         // Retorna o tamanho ocupado pelo arquivo em bytes 
  METHOD RecSize()			// Retorna o tamanho de um registro da tabela 
  METHOD LUpdate()			// Retorna a data interna do arquivo que registra o ultimo update 
 
  // ========================= Metodos de uso interno da classe

  METHOD _InitVars() 		// Inicializa propriedades do Objeto, no construtor e no CLOSE
  METHOD _ReadHeader()		// Lê o Header do arquivo  de dados
  METHOD _ReadStruct()		// Lê a estrutura do arquivo de dados 
  METHOD _SetLUpdate()      // Atualiza data do Last Update no Header do Arquivo 
  METHOD _ReadRecord()		// Le um registro do arquivo de dados
  METHOD _ClearRecord()		// Limpa o registro da memoria (EOF por exemplo) 
  METHOD _ReadMemo()        // Recupera um conteudo de campo memo por OFFSET

ENDCLASS

// ----------------------------------------------------------
// Retorna o tipo do arquivo 

METHOD GetFileType() CLASS TIDBF 
Return "DBF"

// ----------------------------------------------------------
// Construtor do objeto DBF 
// Apenas recebe o nome do arquivo e inicializa as propriedades
// Inicializa o TIISAM passando a instancia atual 

METHOD NEW(cFile,oFileDef) CLASS TIDBF 
    _Super:New(self)

    ::_InitVars() 
    ::cDataFile   := lower(cFile)

    If oFileDef != NIL 
        // Passa a definição pro IsamFile 
        ::SetFileDef(oFileDef)
    Endif

Return self


// ----------------------------------------------------------
// Abertura da tabela -- READ ONLE 
// Caso retorne .F. , consulte o ultimo erro usando GetErrorStr() / GetErrorCode()
// Por hora apenas a abertura possui tratamento de erro 

METHOD OPEN(lExclusive,lCanWrite) CLASS TIDBF 
    Local nFMode := 0

    ::_ResetError()

    If ::lOpened
        ::_SetError(-1,"File Already Open")
        Return .F.
    Endif

    IF !::Exists()
        ::_SetError(-6,"Unable to OPEN - File ["+::cDataFile+"] DOES NOT EXIST")
        Return .F.
    Endif

    If lExclusive = NIL ; 	lExclusive := .F. ; Endif
    If lCanWrite = NIL ; 	lCanWrite := .F.  ; Endif

    If lExclusive
        nFMode += FO_EXCLUSIVE
    Else
        nFMode += FO_SHARED
    Endif

    If lCanWrite
        nFMode += FO_READWRITE
    Else
        nFMode += FO_READ
    Endif

    // Por enquanto faz escrita apenas em modo exclusivo
    If lCanWrite .AND. !lExclusive
        ::_SetError(-6,"Unable to OPEN for WRITE in SHARED MODE -- Use Exclusive mode or OPEN FOR READ")
        Return .F.
    Endif

    // Atualiza propriedades de controle da classe
    ::lExclusive   := lExclusive
    ::lCanWrite    := lCanWrite

    // Abre o arquivo de dados
    ::nHData := Fopen(::cDataFile,nFMode)

    If ::nHData == -1
        ::_SetError(-2,"Open Error - File ["+::cDataFile+"] Mode ["+cValToChar(nFMode)+"] - FERROR "+cValToChar(Ferror()))
        Return .F.
    Endif

    // Lê o Header do arquivo 
    If !::_ReadHEader()
        FClose(::nHData)
        ::nHData := -1
        Return .F. 
    Endif

    If ::lHasMemo

        // Se o header informa que a tabela possui campo MEMO 
        // Determina o nome do arquivo MEMO 

        ::cMemoFile := substr(::cDataFile,1,rat(".",::cDataFile)-1)
        ::cMemoFile += ::cMemoExt
        
        If !file(::cMemoFile)
            ::_SetError(-3,"Memo file ["+::cMemoFile+"] NOT FOUND.")
            ::Close()
            Return .F. 
        Endif

        If ::nMemoType == 1
            ::oMemoFile  := TIDBT():New(self,::cMemoFile)
        ElseIF ::nMemoType == 2
            ::oMemoFile  := TIFPT():New(self,::cMemoFile)
        Endif

        If !::oMemoFile:Open(::lExclusive,::lCanWrite)
            ::_SetError(-4,"Open Error - File ["+::cMemoFile+"] - FERROR "+cValToChar(Ferror()))
            ::Close()
            Return .F. 
        Endif
        
    Endif

    If !::_ReadStruct()

        // Em caso de falha na leitura da estrutura 

        FClose(::nHData)
        ::nHData := -1
        
        IF ::oMemoFile != NIL 
            ::oMemoFile:Close()
            FreeObj(::oMemoFile)
        Endif

        Return .F.
        
    Endif

    // Cria o array de campos do registro atual 
    ::aGetRecord := Array(::nFldCount)
    ::aPutRecord := Array(::nFldCount)

    // Seta que o arquivo está aberto 
    ::lOpened := .T. 

    // Vai para o topo do arquivo 
    // e Lê o primeiro registro físico 
    ::GoTop()

Return .T. 


// ----------------------------------------------------------
// Fecha a tabela aberta 
// Limpa as variaveis de controle. 
// A tabela pode ser aberta novamente pela mesma instancia 

METHOD CLOSE() CLASS TIDBF 

    // Fecha o arquivo aberto 
    If ::nHData <> -1
        fClose(::nHData)
    Endif

    // Se tem memo, fecha 
    IF ::oMemoFile != NIL 
        ::oMemoFile:Close()
        FreeObj(::oMemoFile)
    Endif

    // Fecha todos os indices abertos 
    ::ClearIndex()

    // Limpa as propriedades
    ::_InitVars()

Return 


// ----------------------------------------------------------\
// Verifica se a tabela existe no disco 
METHOD EXISTS() CLASS TIDBF 
    IF File(::cDataFile)
        Return .T. 
    Endif
Return .F. 

// ----------------------------------------------------------\
// Cria a tabela no disco 
// O nome já foi recebido no construtor 
// Recebe a estrutura e a partir dela cria a tabela 
// Se o objeto já está atrelado a uma definição, usa a estrutura da definição 

METHOD CREATE( aStru ) CLASS TIDBF 
    Local lHasMemo := .F.
    Local nFields := 0
    Local nRecSize := 1 
    Local nI, nH
    Local cNewHeader := ''
    Local lOk, cMemoFile, oMemoFile
    Local cFldName

    If ::EXISTS()
        ::_SetError(-7,"CREATE ERROR - File Already Exists")
    Endif

    If ::lOpened
        ::_SetError(-8,"CREATE ERROR - File Already Opened")
    Endif

    If aStru = NIL .AND. ::oFileDef != NIL 
        // Se a erstrutura nao foi informada 
        // Mas a tabela tem a definição , 
        // pega a estrutura da definicao 
        aStru := ::oFileDef:GetStruct()
    Endif

    nFields := len(aStru)

    For nI := 1 to nFields
        If aStru[nI][2] == 'M'
            lHasMemo := .T. 
        Endif
        If !aStru[nI][2]$"CNDLM"
            UserException("CREATE ERROR - INVALID FIELD TYPE "+aStru[nI][2]+ " ("+aStru[nI][1]+")" )
        Endif
        // Ajusta nome do campo 
        aStru[nI][1] := Upper(padr(aStru[nI][1],10))
        nRecSize += aStru[nI][3]
    Next

    // Inicio do Header
    // 1o Byte - Formato do aRquivo 
    // Campo memo será criado como FPT 
    If lHasMemo
        ::nMemoType := 2
        cNewHeader += Chr(245) // FoxPro 2.x (or earlier) with memo ( FPT ) 
    Else
        cNewHeader += chr(003) // FoxBASE+/Dbase III plus, no memo
    Endif

    // 3 Byte(2) = Last Update Date = TODAY
    cNewHeader +=  chr( Year(date())-2000 ) + ;
                chr( Month(date()) ) + ;
                Chr( Day(date()) ) 

    // 4 byte(S) - Last Record
    cNewHeader +=  L2BIN(0) 

    // 2 byte(s) -- Begin Data Offset
    cNewHeader +=  I2Bin( ( (nFields+1) * 32) + 2 ) 

    // 2 byte(s) -- Record Size 
    cNewHeader +=  I2Bin(nRecSize) 

    // Filler ( 32 Bytes  )
    cNewHeader +=  replicate( chr(0) , 4 )
    cNewHeader +=  replicate( chr(0) , 16 )

    // Acrescenta no Header a estrutura
    For nI := 1 to nFields

        cFldName := alltrim(aStru[nI][1])
        while len(cFldName) < 10
            cFldName += chr(0)
        Enddo

        cNewHeader +=  cFldName + chr(0) // Nome
        cNewHeader +=  aStru[nI][2]  // Tipo 
        cNewHeader +=  replicate( chr(0) , 4 ) // Filler - Reserved
        cNewHeader +=  chr(aStru[nI][3]) // Size
        cNewHeader +=  chr(aStru[nI][4]) // Decimal
        cNewHeader +=  replicate( chr(0) , 14 ) // Filler - Reserved

    Next

    // Final do Header apos estrutura 

    cNewHeader +=  chr(13)  // 0x0D = Fim da estrutura 
    cNewHeader +=  chr(0)   // 0c00 = Filler
    cNewHeader +=  chr(26)  // 0x1A = End Of File

    // Cria a tabela no disco 
    nH := fCreate(::cDataFile)

    If nH == -1
        ::_SetError(-9,"CREATE ERROR - Data File ["+::cDataFile+"] - FERROR ("+cValToChar(Ferror())+")")
        Return .F. 
    Endif

    fWrite(nH,cNewHeader)
    fCLose(nH)

    If lHasMemo
        cMemoFile := substr(::cDataFile,1,rat(".",::cDataFile)-1)
        cMemoFile += '.fpt'
        oMemoFile := TIFPT():New(self,cMemoFile)
        lOk := oMemoFile:Create()
        FreeObj(oMemoFile)
        If !lOk
            ::_SetError(-9,"CREATE ERROR - Data File ["+::cDataFile+"] - FERROR ("+cValToChar(Ferror())+")")
            Return .F. 
        Endif
    Endif

Return .T. 


// ----------------------------------------------------------\
// Apaga a tabela do disco 

METHOD DROP() CLASS TIDBF 
    nErr := 0

    If ::lOpened
        ::_SetError(-8,"DROP ERROR - File Already Opened")
        Return .F.
    Endif

    If !empty(cDataFile)
        Ferase(cDataFile)
    Endif

    If !empty(cMemoFile)
        Ferase(cMemoFile)
    Endif

Return .T. 

// ----------------------------------------------------------
// Permite ligar filtro de navegação de registros deletados
// Defaul = desligado

METHOD SetDeleted( lSet ) CLASS TIDBF 
    Local lOldSet := ::lSetDeleted
    If pCount() > 0 
        ::lSetDeleted := lSet
    Endif
Return lOldSet


// ----------------------------------------------------------
// *** METODO DE USO INTERNO ***
// Inicializa / Limpa as propriedades padrao do Objeto 

METHOD _InitVars() CLASS TIDBF 

    // Inicialização das propriedades da classe pai
    _Super:_InitVars()

    ::nHData      := -1
    ::lOpened     := .F. 
    ::nDataPos    := 0 
    ::lHasMemo    := .F. 
    ::lExclusive  := .F. 
    ::lCanWrite   := .T. 
    ::dLastUpd    := ctod("")
    ::aPutRecord  := {}
    ::lUpdPend    := .F. 
    ::lNewRecord  := .F.
    ::lDeleted    := .F. 
    ::lSetDeleted := .F. 
    ::nRecno      := 0
    ::cMemoExt    := ''
    ::nMemoType   := 0 


Return

// ----------------------------------------------------------
// Retorna o identificador hexadecimal do tipo do DBF

METHOD GetDBType() CLASS TIDBF 
Return ::cDBFType

// ----------------------------------------------------------
// Tipo do MEMO usado, 1 = DBT , 2 = FPT

METHOD GetMemoType()  CLASS TIDBF 
Return ::nMemoType

// ======================================================================================================
// Array com os tipos de DBF reconhecidos 
// O 3o elemento quando .T. indoca se o formato é suportado 

STATIC _aDbTypes := { { '0x02','FoxBASE'                                              , .F. } , ;
                      { '0x03','FoxBASE+/Dbase III plus, no memo'                     , .T. } , ;  // ####  (No Memo)
                      { '0x04','dBASE IV or IV w/o memo file'                         , .F. } , ;
                      { '0x05','dBASE V w/o memo file'                                , .F. } , ;
                      { '0x30','Visual FoxPro'                                        , .F. } , ;
                      { '0x31','Visual FoxPro, autoincrement enabled'                 , .F. } , ;
                      { '0x32','Visual FoxPro, Varchar, Varbinary, or Blob-enabled'   , .F. } , ;
                      { '0x43','dBASE IV SQL table files, no memo'                    , .F. } , ;
                      { '0x63','dBASE IV SQL system files, no memo'                   , .F. } , ;
                      { '0x7B','dBASE IV with memo'                                   , .F. } , ;
                      { '0x83','FoxBASE+/dBASE III PLUS, with memo'                   , .T. } , ;  // ####  DBT
                      { '0x8B','dBASE IV with memo'                                   , .F. } , ;
                      { '0x8E','dBASE IV w. SQL table'                                , .F. } , ;
                      { '0xCB','dBASE IV SQL table files, with memo'                  , .F. } , ;
                      { '0xF5','FoxPro 2.x (or earlier) with memo'                    , .T. } , ;  // ####  FPT
                      { '0xE5','HiPer-Six format with SMT memo file'                  , .F. } , ;
                      { '0xFB','FoxBASE'                                              , .F. } } 

// ======================================================================================================


// ----------------------------------------------------------
// Retorna a descrição do tipo de arquivo DBF 

METHOD GetDBTypeStr() CLASS TIDBF
    Local cRet := '(Unknow DBF Type)'
    Local nPos := ascan(_aDbTypes,{|x| x[1] == ::cDBFType })

    If nPos > 0
        cRet := _aDbTypes[nPos][2]
    Endif
Return cREt

// ----------------------------------------------------------
// Retorna a data do ultimo update feito no arquivo 

METHOD LUPDATE() CLASS TIDBF 
Return ::dLastUpd

// ----------------------------------------------------------
// *** METODO DE USO INTERNO ***
// Realiza a leitura do Header do arquivo DBF 

METHOD _ReadHeader() CLASS TIDBF 
    Local cBuffer := space(32)
    Local nYear, nMonth, nDay
    Local cTemp := ''
    Local nTemp := 0

    If ::nHData == -1 
        UserException("_ReadHeader() ERROR - DBF File Not Opened")
    Endif

    // Reposicionao o arquivo no Offset 0
    // Le os primeiros 32 bytes do Header
    FSeek(::nHData,0)
    FRead(::nHData,@cBuffer,32)

    // ----------------------------------------
    // Database File Type

    cTemp := DBF_OFFSET(cBuffer,0,1)       
    nTemp := ASC(cTemp)

    ::cDBFType := '0x'+padl( upper(DEC2HEX(nTemp)) , 2 , '0')
                                    
    If ::cDBFType == '0x83'   
        // FoxBASE+/dBASE III PLUS, with memo
        ::lHasMemo := .T. 
        ::cMemoExt := ".dbt"
        ::nMemoType := 1
    ElseIf ::cDBFType == '0xF5'
        // FoxPro 2.x (or earlier) with memo
        ::lHasMemo := .T. 
        ::cMemoExt := ".fpt"
        ::nMemoType := 2
    Endif

    If Ascan(_aDbTypes,{|x| x[1] == ::cDBFType }) == 0 
        ::_SetError(-5,"DBF FORMAT ("+::cDBFType+") NOT RECOGNIZED")
        Return .F. 
    Endif

    // ----------------------------------------
    // Last Update ( YMD => 3 Bytes, binary )

    cTemp := DBF_OFFSET(cBuffer,1,3) 

    nYear  := ASC( substr(cTemp,1,1))
    nMonth := ASC( substr(cTemp,2,1))
    nDay   := ASC( substr(cTemp,3,1))

    If nYear < 50 
        nYear += 2000
    Else
        nYear += 1900
    Endif

    ::dLastUpd := ctod(strzero(nDay,2)+"/"+strzero(nMonth,2)+"/"+strzero(nYear,4))

    // ----------------------------------------
    // 4 bytes (32 bits), Record Count (  LastRec ) 

    cTemp := DBF_OFFSET(cBuffer,4,4) 
    ::nLastRec := Bin2L(cTemp)

    // ----------------------------------------
    // First Data Record Position  ( Offset ) 

    cTemp := DBF_OFFSET(cBuffer,8,2) 
    ::nDataPos := Bin2I(cTemp)

    // ----------------------------------------
    // Length of one data record, including delete flag

    cTemp := DBF_OFFSET(cBuffer,10,2) 
    ::nRecLength := Bin2I(cTemp)

    // Limpeza de variáveis 
    cTemp := NIL
    cBuffer := NIL

Return .T. 


/*
FIELD DESCRIPTOR ARRAY TABLE
BYTES DESCRIPTION
0-10 Field Name ASCII padded with 0x00
11 Field Type Identifier (see table)
12-15 Displacement of field in record
16 Field length in bytes
17 Field decimal places
18-19 Reserved
20 dBaseIV work area ID
21-30 Reserved
31 Field is part of production index - 0x01 else 0x00
*/

// ----------------------------------------------------------
// *** METODO DE USO INTERNO ***
// Lê a estrutura de campos da tabela 

METHOD _ReadStruct() CLASS TIDBF 
    Local cFldBuff := space(32)
    Local cFldName, cFldType  , nFldLen , nFldDec 

    If ::nHData == -1 
        UserException("_ReadStruct() ERROR - DBF File Not Opened")
    Endif

    // Reposicionao o arquivo no Offset 32
    FSeek(::nHData,32)

    While .T.

        FRead(::nHData,@cFldBuff,32)
        
        If substr(cFldBuff,1,1) == chr(13) 
            // 0x0D => Indica final da estrutura
            EXIT
        Endif
        
        cFldName := DBF_OFFSET(cFldBuff,0,11)
        cFldName := left( cFldName,AT(chr(0),cFldName )-1 )
        cFldName := padr(cFldName,10)
        
        cFldType := DBF_OFFSET(cFldBuff,11,1)

        nFldLen  := ASC(DBF_OFFSET(cFldBuff,16,1))
        nFldDec  := ASC(DBF_OFFSET(cFldBuff,17,1))
        
        aadd(::aStruct , { cFldName , cFldType , nFldLen , nFldDec } )

    Enddo

    ::nFldCount := len(::aStruct)

Return .T. 

// ----------------------------------------------------------
// Recupera o conteúdo de um campo da tabela 
// a partir da posiçao do campo na estrutura

METHOD FieldGet(nPos) CLASS TIDBF 
     
    If valtype(nPos) = 'C'
        nPos := ::FieldPos(nPos)
    Endif

    If nPos > 0 .and. nPos <= ::nFldCount 

        IF ::aStruct[nPos][2] == 'M'
            // Campo MEMO, faz a leitura baseado 
            // no Bloco gravado na tabela 
            Return ::_ReadMemo( ::aGetRecord[nPos] )
        Else
            Return ::aGetRecord[nPos]
        Endif
        
    Endif

Return NIL


// ----------------------------------------------------------
// Atualiza um valor na coluna informada do registro atual 
// Por hora nao critica nada, apenas coloca o valor no array 

METHOD FieldPut(nPos,xValue) CLASS TIDBF 

    If valtype(nPos) = 'C'
        nPos := ::FieldPos(nPos)
    Endif

    If ( !::lCanWrite )
        UserException("Invalid FieldPut() -- File NOT OPEN for WRITING")
    Endif

    If ( ::lEOF )
        UserException("Invalid FieldPut() -- File is in EOF")
    Endif

    If nPos > 0 .and. nPos <= ::nFldCount 
        If ::aStruct[nPos][2] == 'C'
            // Ajusta tamanho de string com espaços a direita
            xValue := PadR(xValue,::aStruct[nPos][3])
        Endif
        ::aPutRecord[nPos] := xValue
        ::lUpdPend := .T. 
    Endif

Return NIL

// ----------------------------------------------------------
// Recupera o nome do arquivo no disco 
METHOD FileName() CLASS TIDBF 
Return ::cDataFile

// ----------------------------------------
// Retorna .T. caso o registro atual esteja deletado 
METHOD DELETED() CLASS TIDBF 
Return ::lDeleted

// ----------------------------------------
// Retorna o tamanho do HEader
// -- O tamanho do Header é justamente a posicao do offser de dados 
// da tabela, após o final do Header. 

METHOD HEADER() CLASS TIDBF 
Return ::nDataPos

// ----------------------------------------
// Retorna o tamanho ocupado pelo arquivo em bytes 
METHOD FileSize() CLASS TIDBF 
    Local nFileSize := 0
    If ::lOpened
        nFileSize := fSeek(::nHData,0,2)
    Endif
Return nFileSize

// ----------------------------------------
// Retorna o tamanho de um registro da tabela no arquivo 
// Cada campo MEMO ocupa 10 bytes 

METHOD RECSIZE() CLASS TIDBF 
Return ::nRecLength

// ----------------------------------------
// Retorna o numero do registro atualmente posicionado

METHOD RECNO() CLASS TIDBF 
    If ::lEOF
        Return ::nLastRec+1
    Endif
Return ::nRecno 

// ----------------------------------------
// *** METODO DE USO INTERNO ***
// Lê o registro posicionado no offset de dados atual 

METHOD _ReadRecord() CLASS TIDBF 
    Local cTipo , nTam , cValue
    Local nBuffPos := 2 , nI
    Local cRecord := '' , nOffset

    // ----------------------------------------
    // Calcula o offset do registro atual baseado no RECNO

    nOffset := ::nDataPos 
    nOffset += (::nRecno * ::nRecLength)
    nOffset -= ::nRecLength

    // Posiciona o arquivo de dados no offset do registro 
    FSeek(::nHData , nOffset )

    // Lê o registro do offset atual 
    FRead(::nHData , @cRecord , ::nRecLength )

    // Primeiro byte = Flag de deletato
    // Pode ser " " (espaço)    registro ativo 
    //          "*" (asterisco) registro deletado 
    
    ::lDeleted := ( left(cRecord,1) = '*' )

    // Agora lê os demais campos e coloca no ::aGetRecord

    For nI := 1 to ::nFldCount

        cTipo := ::aStruct[nI][2]
        nTam  := ::aStruct[nI][3]
        cValue := substr(cRecord,nBuffPos,nTam)

        If cTipo == 'C'
            ::aGetRecord[nI] := cValue
            nBuffPos += nTam
        ElseIf cTipo == 'N'
            ::aGetRecord[nI] := val(cValue)
            nBuffPos += nTam
        ElseIf cTipo == 'D'
            ::aGetRecord[nI] := STOD(cValue)
            nBuffPos += nTam
        ElseIf cTipo == 'L'
            ::aGetRecord[nI] := ( cValue=='T' )
            nBuffPos += nTam
        ElseIf cTipo == 'M'
            // Recupera o Offset do campo no DBT/FPT
            // aGetRecord sempre vai conter o OFFSET
            ::aGetRecord[nI] := val(cValue)
            nBuffPos += nTam
        Endif
    
    Next

    // Reseta flags de BOF e EOF 
    ::lBOF := .F. 
    ::lEOF := .F. 

Return .T. 


// ----------------------------------------
// Insere um registro em branco no final da tabela
// Apos a inserção, voce pode fazer fieldput 
// e confirmar tudo com UPDATE 
METHOD Insert() CLASS TIDBF

    If ::lUpdPend
        // Antes de mais nada, se tem um update pendente
        // Faz primeiro o update 
        ::Update()
    Endif

    // Limpa o conteudo do registro 
    ::_ClearRecord()

    // Nao estou em BOF ou EOF, 
    // Estou em modo de inserção de registro
    ::lBOF := .F. 
    ::lEOF := .F. 
                
    // Incrementa uma unidade no contador de registros
    ::nLastRec++

    // Recno atual = registro novo 
    ::nRecno := ::nLastRec

    // Cria uma pendencia de update 
    // O update vai fazer a inserção no final do arquivo 
    ::lNewRecord := .T.

    // Faz o update inserir o registro em branco 
    IF ::Update()
                
        // Escreve o novo final de arquivo 
        FSeek(::nHData,0,2)
        fWrite(::nHData , chr(26) ) // !a = End Of File 

        // Atualiza o numero do ultimo registro no Header
        FSeek(::nHData,4)
        fWrite(::nHData , L2Bin(::nLastRec) )
        
        Return .T. 

    Endif

Return .F. 

// ----------------------------------------
// Grava as alterações do registro atual na tabela 

METHOD Update() CLASS TIDBF
    Local cTipo , nTam , xValue
    Local nI
    Local cSaveRec := '' , nOffset
    Local nMemoBlock, nNewBlock

    If ( ::lEOF )
        UserException("TIDBF::Update() ERROR -- File is in EOF")
        Return
    Endif

    If !::lUpdPend .and. !::lNewRecord
        // Nao tem insert e nao tem update pendente, nao faz nada
        Return
    Endif

    // ----------------------------------------
    // Calcula o offset do registro atual baseado no RECNO

    nOffset := ::nDataPos 
    nOffset += (::nRecno * ::nRecLength)
    nOffset -= ::nRecLength

    // Primeiro byte do registro
    // Flag de deletado 
    cSaveRec := IIF(::lDeleted ,'*',' ') 

    // Agora concatena os demais campos 
    // Se nao houve alteração, monta o buffer com o valor lido

    For nI := 1 to ::nFldCount

        cTipo := ::aStruct[nI][2]
        nTam  := ::aStruct[nI][3]
        nDec  := ::aStruct[nI][4]

        If cTipo == 'C'

            If ::aPutRecord[nI] != NIL 
                xValue := PADR( ::aPutRecord[nI] ,nTam)
                cSaveRec += xValue
                ::aPutRecord[nI] := NIL
                ::aGetRecord[nI] := xValue
            Else
                cSaveRec += ::aGetRecord[nI]
            Endif	

        ElseIf cTipo == 'N'

            If ::aPutRecord[nI] != NIL 
                xValue := ::aPutRecord[nI]
                cSaveRec += STR( xValue , nTam, nDec)
                ::aPutRecord[nI] := NIL
                ::aGetRecord[nI] := xValue
            Else
                cSaveRec += STR( ::aGetRecord[nI], nTam, nDec)
            Endif

        ElseIf cTipo == 'D'

            If ::aPutRecord[nI] != NIL 
                xValue := ::aPutRecord[nI]
                cSaveRec += DTOS( xValue )
                ::aPutRecord[nI] := NIL
                ::aGetRecord[nI] := xValue
            Else
                cSaveRec += DTOS( ::aGetRecord[nI] )
            Endif

        ElseIf cTipo == 'L'

            If ::aPutRecord[nI] != NIL 
                xValue := ::aPutRecord[nI]
                cSaveRec += IIF( xValue , 'T' , 'F')
                ::aPutRecord[nI] := NIL
                ::aGetRecord[nI] := xValue
            Else
                cSaveRec += IIF( ::aGetRecord[nI] , 'T' , 'F')
            Endif


        ElseIf cTipo == 'M'

            // Update de campo memo
            // Se realmente foi feito uma troca de valor, vamos ver o que fazer 
            // O bloco usado ( caso tivesse um ) está no ::aGetRecord[nI]

            If ::aPutRecord[nI] != NIL 

                // Pega o valor a atualizar no campo memo 
                xValue := ::aPutRecord[nI]
                
                // Verifica o numero do bloco usado 
                // 0 = sem bloco , sem conteudo 
                nMemoBlock := ::aGetRecord[nI]
                
                // Faz update deste memo. Se nao usava bloco, pode passar
                // a usar. Se já usava, se o memo nao for maior do que o já existente
                // ou nao atingir o limite do block, pode usar o mesmo espaço
                nNewBlock := ::oMemoFile:WRITEMEMO( nMemoBlock , xValue ) 
                
                If nNewBlock <> nMemoBlock
                    // Trocou de bloco 
                    cSaveRec += str( nNewBlock , 10 )
                    // Atualiza a variavel de memoria 
                    ::aGetRecord[nI] := nNewBlock
                Else
                    // Manteve o bloco 
                    cSaveRec += str( nMemoBlock , 10 )
                Endif
            
            Else

                // Memo nao foi atualizado. 
                // Mantem valor atual 
                cSaveRec += STR( ::aGetRecord[nI] , 10 )

            Endif
            
        Endif

    Next

    IF len(cSaveRec) > ::nRecLength
        // Jamais, nunca. 
        // Se meu buffer em memoria passou o tamanho do registro 
        // do arquivo, algo deu muito errado ... 
        UserException("TIDBF::Update() ERROR - FIELD BUFFER OVERFLOW")
    Endif

    // Posiciona o arquivo de dados no offset do registro 
    FSeek(::nHData , nOffset )

    // Agora grava o buffer do registro inteiro 
    fWrite(::nHData , cSaveRec , ::nRecLength )

    // Desliga flag de update pendente 
    ::lUpdPend := .F. 

    // Atualiza o header do DBF com a data do ultimo update 
    // caso necessario \

    If Date() > ::dLastUpd 
        // Atualiza a data em memoria 
        ::dLastUpd  := Date()
        // Regrava a nova data no header 
        ::_SetLUpdate()
    Endif

    // Agora que o registro está atualizado, atualiza os indices 
    if (::lNewRecord)
        // Inserção de registro, desliga o flag de inserção 
        ::lNewRecord := .F. 
        // Insere a nova chave em todos os indices abertos
        aEval(::aIndexes , {|oIndex| oIndex:InsertKey() })
    Else
        // Atualiza a chave de todos os indices abertos
        aEval(::aIndexes , {|oIndex| oIndex:UpdateKey() })
    Endif

Return .T. 

// ----------------------------------------------------------
// *** METODO DE USO INTERNO ***
// Atualiza o header da tabela com a data atualizada
// do ultimo update realizado na tabela 
// Metodo chamado apenas quando a data do header 
// da tabela estiver desatualizada 

METHOD _SetLUpdate() CLASS TIDBF
    Local cBuffer

    // Vai para o offset 1 -- 3 bytes com a data do ultimo update 
    FSeek(::nHData,1)

    // Monta a nova data em 3 bytes 
    cBuffer := chr( Year(::dLastUpd)-2000 ) + ;
            chr( Month(::dLastUpd) ) + ;
            Chr( Day(::dLastUpd) ) 

    // Grava a nova data no header 
    fWrite(::nHData , cBuffer)

Return

// ----------------------------------------------------------
// *** METODO DE USO INTERNO ***
// Limpa os campos do registro atual 
// ( Inicializa todos com os valores DEFAULT ) 

METHOD _ClearRecord()  CLASS TIDBF

    // Inicializa com o valor default os campos da estrutura 
    _Super:_ClearRecord()

    // Limpa flag de registro deletado 
    ::lDeleted := .F. 

Return

// ----------------------------------------
// *** METODO DE USO INTERNO ***
// Lë um campo MEMO de um arquivo DBT 
// baseado no numero do bloco rececido como parametro 

METHOD _ReadMemo(nBlock) CLASS TIDBF
    Local cMemo := '' 

    If nBlock > 0

        // Le o conteúdo do campo MEMO 
        cMemo := ::oMemoFile:ReadMemo(nBlock)

    Endif

Return cMemo


CLASS TIDBT FROM LONGNAMECLASS

   DATA oDBF
   DATA cFileName
   DATA nHMemo

   METHOD NEW()
   METHOD OPEN()
   METHOD CLOSE()
   METHOD READMEMO()
   METHOD WRITEMEMO()

ENDCLASS
              
// ----------------------------------------------------------

METHOD NEW(_oDBF,_cFileName) CLASS TIDBT
    ::oDBF      := _oDBF
    ::cFileName := _cFileName
    ::nHMemo    := -1

Return self


// ----------------------------------------------------------

METHOD OPEN() CLASS TIDBT
    // Abre o arquivo MEMO 
    ::nHMemo := FOpen(::cFileName)

    IF ::nHMemo == -1
    	Return .T. 
    Endif

Return .T. 

// ----------------------------------------------------------

METHOD CLOSE() CLASS TIDBT

    IF ::nHMemo != -1
	fClose(::nHMemo)
	::nHMemo := -1
    Endif

Return


// ----------------------------------------------------------

METHOD READMEMO(nBlock) CLASS TIDBT
    Local cMemo   := ''
    Local cBlock  := space(512)
    Local nFilePos := nBlock * 512
    Local nEndPos

    fSeek(::nHMemo , nFilePos)

    While .T.
        fRead(::nHMemo,@cBlock,512)
        nEndPos := at(chr(26),cBlock)
        If nEndPos > 0
            cBlock := left(cBlock,nEndPos-1)
            cMemo += cBlock
            EXIT
        Else
            cMemo += cBlock
        Endif
    Enddo

    // -- Quebra de linha "soft" = 8D 0A
    // -- Remove a quebra
    cMemo := strtran(cMemo , chr(141)+chr(10) , '' )

Return cMemo


METHOD WRITEMEMO( nBlock , cMemo ) CLASS TIDBT
    UserException("*** WRITEMEMO NOT AVAILABLE FOR DBT MEMO FILE ***")
Return

// funcoes staticas 
/* ======================================================

Funcao de Comparação zCompare()

Comparação de tipo e conteúdo exatamente igual
Compara também arrays.

Retorno :

0 = Conteúdos idênticos
-1 = Tipos diferentes
-2 = Conteúdo diferente
-3 = Numero de elementos (Array) diferente

====================================================== */

STATIC Function zCompare(xValue1,xValue2)
    Local cType1 := valtype(xValue1)
    Local nI, nT, nRet := 0

    If cType1 == valtype(xValue2)
        If cType1 = 'A'
            // Comparação de Arrays 
            nT := len(xValue1)
            If nT <> len(xValue2)
                // Tamanho do array diferente
                nRet := -3
            Else
                // Compara os elementos
                For nI := 1 to nT
                    nRet := zCompare(xValue1[nI],xValue2[nI])
                    If nRet < 0
                        // Achou uma diferença, retorna 
                        EXIT
                    Endif
                Next
            Endif
        Else
            If !( xValue1 == xValue2 )
                // Conteudo diferente
                nRet := -2
            Endif
        Endif
    Else
        // Tipos diferentes
        nRet := -1
    Endif

Return nRet



CLASS TIFPT FROM LONGNAMECLASS

   DATA oDBF                 // Objeto TIDBF owner do MEMO 
   DATA cFileName            // Nome do arquivo FPT
   DATA nHMemo               // Handler do arquivo 
   DATA nNextBlock           // Proximo bloco para inserção de dados 
   DATA nBlockSize           // Tamanho do bloco em bytes 
   DATA lExclusive           // Arquivo aberto em modo exclusivo ?
   DATA lCanWrite            // Arquivo aberto para gravacao 

   METHOD NEW()              // Construtor
   METHOD CREATE()           // Cria o arquivo 
   METHOD OPEN()             // Abre o FPT 
   METHOD CLOSE()            // Fecha o FPT
   METHOD READMEMO()         // Le um memo armazenado em um bloco
   METHOD WRITEMEMO()        // Insere ou atualiza um memo em um bloco 

ENDCLASS
              
// ----------------------------------------------------------
// Construtor
// Recebe o objeto TIDBF e o nome do arquivo FPT 

METHOD NEW(_oDBF,_cFileName) CLASS TIFPT

    ::oDBF       := _oDBF
    ::cFileName  := _cFileName
    ::nHMemo     := -1
    ::nBlockSize := 16384
    ::nNextBlock := 1 
    ::lExclusive := .F.
    ::lCanWrite  := .F.

Return self


// ----------------------------------------------------------
// Criação do arquivo 
// Cria um arquivo FPT vazio 

METHOD CREATE() CLASS TIFPT
    Local nHFile, cHeader
    Local cNextBlock, cBlockSize
    Local cFiller1, cFiller2

    // Cria o arquivo MEMO 
    nHFile := FCreate(::cFileName)

    If nHFile == -1
        Return .F.
    Endif

    // Cria o Header ( 512 bytes ) 
    // Block Size = 16 K

    /*
    0 | Number of next        |  ^
    1 | available block       |  |
    2 | for appending data    | Header
    3 | (binary)           *1 |  |
    |-----------------------|  |
    4 | ( Reserved )          |  |    
    5 |                       |  |
    |-----------------------|  |
    6 | Size of blocks N   *1 |  |
    7 |                    *2 |  |
    */

    // ----- Build 512 Bytes FPT Empty File Header -----
    cNextBlock := NtoBin4(1)                     // Proximo bloco livre para escrita 
    cFiller1   := chr(0) + chr(0)               
    cBlockSize := NToBin2( ::nBlockSize )                // Tamanho do Bloco 
    cFiller2   := replicate( chr(0) , 504 )       

    // Monta o Header do arquivo
    cHeader := cNextBlock + cFiller1 + cBlockSize +cFiller2

    // Grava o header em disco 
    fWrite(nHFile,cHEader,512)
    FClose(nHFile)

Return .T. 

// ----------------------------------------------------------
// Abertura do arquivo FPT 
// Recebe os mesmos modos de abertura do TIDBF

METHOD OPEN(lExclusive,lCanWrite) CLASS TIFPT
    Local cBuffer := ''
    Local nFMode := 0 

    If lExclusive = NIL ; 	lExclusive := .F. ; Endif
    If lCanWrite = NIL ; 	lCanWrite := .F.  ; Endif

    ::lExclusive := lExclusive
    ::lCanWrite  := lCanWrite

    If lExclusive
        nFMode += FO_EXCLUSIVE
    Else
        nFMode += FO_SHARED
    Endif

    If lCanWrite
        nFMode += FO_READWRITE
    Else
        nFMode += FO_READ
    Endif

    // Abre o arquivo MEMO 
    ::nHMemo := FOpen(::cFileName,nFMode)

    IF ::nHMemo == -1
        Return .F. 
    Endif

    // Le  o Header do arquivo ( 512 bytes ) 
    fSeek(::nHMemo,0)
    fRead(::nHMemo,@cBuffer,512)

    // Pega o numero do proximo bloco para append 
    ::nNextBlock  := Bin4toN( substr(cBuffer,1,4) )

    // Le o Block Size do arquivo 
    ::nBlockSize := Bin2ToN( substr(cBuffer,7,2) )

    conout("")
    conout("FPT Next Append Block ......: "+cValToChar(::nNextBlock))
    conout("FPT Block Size ...... ......: "+cValToChar(::nBlockSize))
    conout("")


Return .T. 

// ----------------------------------------------------------
// Fecha o arquivo FPT

METHOD CLOSE() CLASS TIFPT

    IF ::nHMemo != -1
        fClose(::nHMemo)
    Endif

    ::nHMemo     := -1
    ::nBlockSize := 16384
    ::nNextBlock := 1 
    ::lExclusive := .F.
    ::lCanWrite  := .F.

Return


// ----------------------------------------------------------
// Lê um campo memo armazenado em um Bloco
// Recebe o número do bloco como parâmetro

METHOD READMEMO(nBlock) CLASS TIFPT
    Local cMemo   := ''
    Local cBlock  := space(8)
    Local nFilePos := nBlock * ::nBlockSize
    Local nRecType

    // Leitura de MEMO em Arquivo FPT
    // Offset 1-4 Record type 
    // Offset 5-8 Tamanho do registro

    fSeek(::nHMemo , nFilePos)
    fRead(::nHMemo,@cBlock,8)

    // Pega o tipo do Registro ( Offset 0 size 4 ) 
    nRecType := Bin4toN( substr(cBlock,1,4) )

    /*	
    Record Type 
    00h	Picture
    01h	Memo
    02h	Object
    */

    If nRecType <> 1 
        UserException("Unsupported MEMO Record Type "+cValToChar(nRecType))
    Endif

    // Obrtém o tamanho do registro ( Offset 4 Size 4 ) 
    nMemoSize := Bin4toN( substr(cBlock,5,4) )

    // Lê o registro direto para a memória
    fRead(::nHMemo,@cMemo,nMemoSize)

Return cMemo


// ------------------------------------------------------------
// Atualiza ou insere um valor em um campo memo 
// Se nBlock = 0 , Conteudo novo 
// Se nBlock > 0 , Conteudo j[a existente 
//
// Release 20190109 - Tratar "limpeza" de campo. 
//                  - Ignorar inserção de string vazia

METHOD WRITEMEMO( nBlock , cMemo ) CLASS TIFPT
    Local nTamFile
    Local nFiller
    Local cBuffer := ''
    Local nFilePos
    Local nMemoSize
    Local nChuckSize
    Local nUsedBlocks
    Local nMaxMemoUpd
    Local nFileSize

    If ( !::lCanWrite )
        UserException("TIFPT::WRITEMEMO() FAILED - FILE OPENED FOR READ ONLY")
    Endif

    If  Len(cMemo) == 0 .AND. nBlock == 0 
        // Atualização de campo memo vazia. 
        // Se o block é zero, estou inserindo, ignora a operação. 
        return 0 
    Endif

    If nBlock > 0
        
        // Eatou atualizando conteúdo
        // verifica se cabe no blocco atual
        // Se nao couber , usa um novo .
        // Primeiro lê o tamanho do campo atual
        // e quantos blocos ele usa
        
        cBuffer  := space(8)
        nFilePos := nBlock * ::nBlockSize
        fSeek(::nHMemo , nFilePos)
        fRead(::nHMemo,@cBuffer,8)
        nMemoSize := Bin4toN( substr(cBuffer,5,4) )
        nChuckSize :=  nMemoSize + 8
        
        // Calcula quantos blocos foram utilizados
        nUsedBlocks := int( nChuckSize / ::nBlockSize )
        IF nChuckSize > ( nUsedBlocks * ::nBlockSize)
            nUsedBlocks++
        Endif
        
        // Calcula o maior campo memo que poderia reaproveitar
        // o(s) bloco(s) usado(s), descontando os 8 bytes de controle
        nMaxMemoUpd := (nUsedBlocks * ::nBlockSize) - 8
        
        If len(cMemo) > nMaxMemoUpd
            
            // Passou, nao dá pra reaproveitar.
            // Zera o nBlock, para alocar um novo bloco
            // Como se o conteudo estivesse sendo inserido agora
            
            nBlock := 0
            
        Else
            
            // Cabe no mesmo bloco ... remonta o novo buffer
            // e atualiza o campo. 
            
            // Mesmo que eu esteja atualizando o campo para uma string vazia 
            // eu mantenho o bloco alocado, para posterior reaproveitamento 
            
            nMemoSize  := len(cMemo)
            nChuckSize :=  nMemoSize + 8
            
            cBuffer := NtoBin4( 01 ) // Tipo de registro = Memo
            cBuffer += NtoBin4( nMemoSize )
            cBuffer += cMemo
            
            // Posiciona no inicio do bloco já usado
            fSeek(::nHMemo , nFilePos)
            fWrite(::nHMemo,cBuffer,nChuckSize)

        Endif
        
    Endif

    If nBlock == 0 
        
        // Pega o tamanho do arquivo 
        nFileSize := fSeek(::nHMemo,0,2)

        // Estou inserindo um conteudo em um campo memo ainda nao utilizado. 
        // Ou estou usando um novo bloco , pois o campo memo 
        // nao cabe no bloco anteriormente utilizado 
        // Utiliza o proximo bloco para inserção do Header
        
        nTamFile := ::nNextBlock * ::nBlockSize

        If nFileSize < nTamFile
            // Se o ultimo bloco do arquivo ainda nao foi preenchido com um "Filler" 
            // até o inicio do proximo bloco , preenche agora
            nFiller := nTamFile - nFileSize
            fSeek(::nHMemo,0,2)
            fWrite(::nHMemo , replicate( chr(0) , nFiller ) , nFiller ) 
        Endif
        
        // Monta o buffer para gravar 
        
        nMemoSize := len(cMemo)
        
        cBuffer := NtoBin4( 01 ) // Tipo de registro = Memo 
        cBuffer += NtoBin4( nMemoSize )
        cBuffer += cMemo
        
        // Tamanho do campo memo no bloco 
        // soma 8 bytes ( tipo , tamanho ) 
        nChuckSize :=  nMemoSize + 8
        
        // Posiciona no proximo bloco livre e grava
        nFilePos := ::nNextBlock * ::nBlockSize 
        fSeek(::nHMemo,nFilePos)
        fWrite(::nHMemo,cBuffer,nChuckSize)
        
        // Guarda o bloco usado para retorno 
        nBlock := ::nNextBlock
        
        // Calcula quantos blocos foram utilizados 
        nUsedBlocks := int( nChuckSize / ::nBlockSize )
        IF nChuckSize > ( nUsedBlocks * ::nBlockSize)
            nUsedBlocks++
        Endif

        // Agora define o proximo bloco livre 
        // Soma no ultimo valor a quantidade de blocos usados 
        ::nNextBlock += nUsedBlocks
        
        // Agora atualiza no Header
        fSeek(::nHMemo,0)
        fWrite( ::nHMemo , nToBin4(::nNextBlock) , 4 )

    Endif

    // Retorna o numero do bloco usado para a operação 
Return nBlock

/* ======================================================================================
Classe       TIISAM
Autor        Julio Wittwer
Data         01/2019
Descrição    A Classe TIISAM serve de base para implementação de tabeas ISAM 
             através de herança. Atualmente é herdada pelas classes TIDBF e ZMEMFILE\
             
Ela serve para unificar os métodos comuns de processamento e lógica de acesso a 
registros em tabela ISAM 
             
====================================================================================== */

CLASS TIISAM FROM LONGNAMECLASS

  DATA cError			    // Descrição do último erro 
  DATA lVerbose             // Modo Verbose (echo em console ligado)
  DATA bFilter              // Codeblock de filtro 
  DATA nIndexOrd            // Ordem de indice atual 
  DATA aIndexes             // Array com objetos de indice 
  DATA oCurrentIndex        // Objeto do indice atual 
  DATA nRecno				// Número do registro (RECNO) atualmnete posicionado 
  DATA nLastRec				// Ultimo registro do arquivo - Total de registros
  DATA aStruct		   		// Array com a estrutura do DBF 
  DATA nFldCount			// Quantidade de campos do arquivo 
  DATA lBOF					// Flag de inicio de arquivo 
  DATA lEOF					// Flag de final de arquivo 
  DATA lOpened              // Indica se o arquivo está aberto 
  DATA lCanWrite            // Arquivo aberto para gravacao 
  DATA aGetRecord			// Array com todas as colunas do registro atual 
  DATA aPutRecord           // Array com campos para update 
  
  DATA oFileDef             // Definição extendida do arquivo 

  METHOD New()              // *** O Construtor nao pode ser chamado diretamente ***
  METHOD GoTo(nRec)		    // Posiciona em um registro informado. 
  METHOD GoTop()			// Posiciona no RECNO 1 da tabela 
  METHOD GoBottom()   	    // Posiciona em LASTREC da tabela 
  METHOD Skip()             // Navegação de registros ISAM 
  METHOD SetFilter()        // Permite setar um filtro para os dados 
  METHOD ClearFilter()      // Limpa o filtro 
  METHOD BOF()				// Retorna .T. caso tenha se tentado navegar antes do primeiro registro 
  METHOD EOF()				// Retorna .T, caso o final de arquivo tenha sido atingido 
  METHOD Lastrec()			// Retorna o total de registros / numero do ultimo registro da tabela 
  METHOD RecCount()			// Retorna o total de registros / numero do ultimo registro da tabela 
  METHOD GetStruct()		// Retorna CLONE da estrutura de dados da tabela 
  METHOD FCount()           // Retorna o numero de campo / colunas da tabela
  METHOD FieldName( nPos )	// Recupera o nome da coluna informada 
  METHOD FieldPos( cField ) // Retorna a posicao de um campo na estrutura da tabela ( ID da Coluna )
  METHOD FieldType( nPos )	// Recupera o tipo da coluna informada 

  METHOD SetOrder()         // Seta um indice / ordem ativa 
  METHOD IndexOrd()         // Retorna a ordem ativa
  METHOD IndexKey()         // Retorna a expressao de indice ativa 
  METHOD IndexValue()       // Retorna o valor da chave de indice do registro atual 
  METHOD Seek(cKeyExpr)     // Realiza uma busca usando o indice ativo 
  METHOD CreateIndex()      // Cria um Indice ( em memoria ) para a tabela 
  METHOD ClearIndex()       // Fecha todos os indices
  METHOD Search()           // Busca um registro que atenda os criterios informados

  METHOD CreateFrom()       // Cria tabela a partir da estrutura do objeto ou alias informado
  METHOD AppendFrom()       // Apenda dados do objeto ou alias informado na tabela atual 
  METHOD Export()           // Exporta o arquivo para um outro formato
  METHOD Import()           // Importa dados de arquivo externo em outro formato ( SDF,CSV,JSON )

  METHOD GetErrorStr()		// Retorna apenas a descrição do último erro ocorrido

  METHOD SetVerbose()       // Liga ou desliga o modo "verbose" da classe
  METHOD IsVerbose()        // Consulta ao modo verbose
  
  METHOD SetFileDef()       // Guarda o objeto da definição do arquivo 


  // ========================= Metodos de uso interno da classe

  METHOD _ResetError()		// Limpa a ultima ocorrencia de erro 
  METHOD _SetError()        // Seta uma nova ocorrencia de erro 
  METHOD _InitVars() 		// Inicializa propriedades  

  METHOD _CheckFilter()     // Verifica se o registro atual está contemplado no filtro 
  METHOD _SkipNext()		// Le o proximo registro da tabela 
  METHOD _SkipPrev()        // Le o registro anterior da tabela 
  METHOD _ClearRecord()     // Limpa o conteudo do registro em memoria 
  METHOD _BuildFieldBlock(cFieldExpr) // Cria codeblock com expressao de campos 

  METHOD _ExportSDF()       // Exporta dados para arquivo SDF
  METHOD _ExportCSV()       // Exporta dados para arquivo CSV
  METHOD _ExportJSON()      // Exporta dados para arquivo JSON
  METHOD _ExportXML()       // Exporta dados para arquivo XML 
 
  METHOD _ImportSDF()       // Importa dados de arquivo SDF
  METHOD _ImportCSV()       // Importa dados de arquivo CSV
  METHOD _ImportJSON()      // Importa dados de arquivo JSON
 
ENDCLASS


// ----------------------------------------
METHOD New() CLASS TIISAM
Return

// ----------------------------------------
// Retorna .T. caso a ultima movimentação de registro 
// tentou ir antes do primeiro registro 
METHOD BOF() CLASS TIISAM 
Return ::lBOF

// ----------------------------------------\
// Retorna .T. caso a tabela esteja em EOF
METHOD EOF() CLASS TIISAM
Return ::lEOF

// ----------------------------------------------------------
// Posiciona diretamente em um regsitro 

METHOD GoTo(nRec)  CLASS TIISAM

    // Verifica se o registro é válido 
    // Se não for, vai para EOF
            
    If nRec > ::nLastRec .or. nRec < 1
        ::lEOF := .T.
        ::_ClearRecord()
        Return
    Endif

    // ----------------------------------------
    // Atualiza o numero do registro atual 
    ::nRecno := nRec

    // Traz o registro atual para a memória
    ::_ReadRecord()

Return

// ----------------------------------------------------------
// Movimenta a tabela para o primeiro registro 
// Release 20190105 : Contempla uso de indice

METHOD GoTop() CLASS TIISAM 

    IF ::nLastRec == 0 
        // Nao há registros 
        ::lBOF := .T. 
        ::lEOF := .T. 
        ::nRecno   := 0
        ::_ClearRecord()
        Return
    Endif

    If ::nIndexOrd > 0 
        // Se tem indice ativo, pergunta pro indice
        // quanl é o primeiro registro da ordem 
        ::nRecno := ::oCurrentIndex:GetFirstRec()
    Else
        // Ordem fisica 
        // Atualiza para o primeiro registtro 
        ::nRecno     := 1
    Endif

    // Traz o registro atual para a memória
    ::_ReadRecord()

    If ( !::_CheckFilter() )
        // Nao passou na verificacao do filtro
        // busca o proximo registro que atenda
        ::_SkipNext()
    Endif

Return

// ----------------------------------------------------------
// Movimenta a tabela para o último registro

METHOD GoBottom() CLASS TIISAM 

    IF ::nLastRec == 0 
        // Nao há registros 
        ::lBOF := .T. 
        ::lEOF := .T. 
        ::nRecno   := 0
        ::_ClearRecord()
        Return
    Endif

    If ::nIndexOrd > 0 
        // Se tem indice ativo, pergunta pro indice
        // quanl é o primeiro registro da ordem 
        ::nRecno := ::oCurrentIndex:GetLastRec()
    Else
        // Ordem fisica 
        // Atualiza o RECNO para o ultimo registro 
        ::nRecno     := ::nLastRec
    Endif

    // Traz o registro atual para a memória
    ::_ReadRecord()

    If ( !::_CheckFilter() )
        // Nao passou na verificacao do filtro
        // busca nos registros anteriores o primeiro que atende
        ::_SkipPrev()
    Endif

Return

// ----------------------------------------------------------
// Avança ou retrocede o ponteiro de registro 
// No caso de DBSkip(0), apenas faz refresh do registro atual   
// Default = 1 ( Próximo Registro ) 

METHOD Skip( nQtd ) CLASS TIISAM
    Local lForward := .T. 

    If nQtd  == NIL
        nQtd := 1
    ElseIF nQtd < 0 
        lForward := .F. 
    Endif

    // Quantidade de registros para mover o ponteiro
    // Se for negativa, remove o sinal 
    nQtd := abs(nQtd)

    While nQtd > 0 
        If lForward
            IF ::_SkipNext()
                nQtd--
            Else
                // Bateu EOF()
                ::_ClearRecord()
                Return
            Endif
        Else
            IF ::_SkipPrev()
                nQtd--
            Else
                // Bateu BOF()
                Return
            Endif
        Endif
    Enddo

    // Traz o registro atual para a memória
    ::_ReadRecord()

Return


// ----------------------------------------------------------
// Permite setar um filtro para a navegação de dados 
// Todos os campos devem estar em letras maiusculas 

METHOD SetFilter( cFilter ) CLASS TIISAM
    Local cFilterBlk

    // retorna string com codebloc para expressao de campos 
    cFilterBlk := ::_BuildFieldBlock(cFilter)

    // Monta efetivamente o codeblock 
    ::bFilter := &(cFilterBlk)

Return .T. 

// ----------------------------------------------------------
// Limpa a expressao de filtro atual 

METHOD ClearFilter() CLASS TIISAM
    ::bFilter := NIL
Return


// ----------------------------------------------------------
// Retorna o numero do ultimo registro da tabela 

METHOD Lastrec() CLASS TIISAM
Return ::nLastRec

// ----------------------------------------------------------
// Colocado apenas por compatibilidade 
// 

METHOD Reccount() CLASS TIISAM
Return ::nLastRec

// ----------------------------------------------------------
// Retorna um clone do Array da estrutura da tabela 

METHOD GetStruct() CLASS TIISAM
Return aClone( ::aStruct )

// ----------------------------------------------------------
// Retorna o numero de campo / colunas da tabela
METHOD FCount()  CLASS TIISAM
Return ::nFldCount

// ----------------------------------------------------------
// Recupera o nome de um campo da tabela 
// a partir da posicao do campo na estrutura

METHOD FieldName(nPos) CLASS TIISAM
    If nPos > 0 .and. nPos <= ::nFldCount 
        Return ::aStruct[nPos][1]
    Endif
Return NIL

// ----------------------------------------------------------
// Recupera o numero do campo na estrutura da tabela 
// a partir do nome do campo 

METHOD FieldPos( cField ) CLASS TIISAM
Return ASCAN( ::aStruct , {|x| x[1] = cField })

// ----------------------------------------------------------
// Recupera o tipo do campo na estrutura da tabela 
// a partir da posicao do campo na estrutura

METHOD FieldType(nPos) CLASS TIISAM
    If nPos > 0 .and. nPos <= ::nFldCount 
        Return ::aStruct[nPos][2]
    Endif
Return NIL

// ----------------------------------------
// Permite trocar a ordedm atual usando 
// um indice aberto 

METHOD SetOrder(nOrd) CLASS TIISAM

    If nOrd < 0 .OR.  nOrd > len( ::aIndexes )
        UserException("DbSetOrder - Invalid Order "+cValToChar(nOrd))
    Endif
    ::nIndexOrd := nOrd
    If ::nIndexOrd > 0 
        ::oCurrentIndex := ::aIndexes[::nIndexOrd]
    Else
        ::oCurrentIndex := NIL
    Endif
Return

// ----------------------------------------
// Retorna o numero da ordem do indce ativo 

METHOD IndexOrd() CLASS TIISAM
Return ::nIndexOrd

// ----------------------------------------
// Retorna a expressao da chave de indice atual 
// Caso nao haja indice ativo, retorna ""

METHOD IndexKey() CLASS TIISAM
    IF ::nIndexOrd > 0 
        Return ::oCurrentIndex:GetIndexExpr()
    Endif
Return ""

// ----------------------------------------
// Retorna o numero da ordem do indce ativo 
METHOD IndexValue() CLASS TIISAM
    IF ::nIndexOrd > 0 
        Return ::oCurrentIndex:GetIndexValue()
    Endif
Return NIL


// ----------------------------------------
// Retorna o numero da ordem do indce ativo 
METHOD Seek(cKeyExpr) CLASS TIISAM
    Local nRecFound := 0

    IF ::nIndexOrd <= 0
        UserException("DBSeek Failed - No active Index")
    Endif

    nRecFound := ::oCurrentIndex:IndexSeek(cKeyExpr)

    If nRecFound > 0
        // NAo precisa resincronizar o indice
        // Eu já fiz a busca pelo indice
        ::nRecno := nRecFound
        ::_ReadRecord()
        Return .T.
    Endif

    // Nao achou nada, vai para EOF 
    ::lEOF := .T.
    ::_ClearRecord()

Return .F.
	
  
// ----------------------------------------
// *** METODO DE USO INTERNO ***
// Cria uma instancia de um indice em memoria 
// Acrescenta na lista de indices 
// Torna o indice ativo e posiciona no primeiro 
// registro da nova ordem 

METHOD CreateIndex(cIndexExpr) CLASS TIISAM
    Local oMemIndex
    Local nLastIndex

    // Cria o objeto do indice passando a instancia
    // do arquivo DBF atual 
    oMemIndex := TIINDEX():New(self)

    // Cria o indice com a expressao informada
    oMemIndex:CreateIndex(cIndexExpr) 

    // Acrescenta o indice criado na tabela 
    aadd(::aIndexes,oMemIndex)

    // E torna este indice atual 
    nLastIndex := len(::aIndexes)
    ::SetOrder( nLastIndex ) 

    // Posiciona no primeiro registro da nova ordem 
    ::GoTop()

Return

// ----------------------------------------
// Fecha todos os indices

METHOD ClearIndex()  CLASS TIISAM
    Local nI

    For nI := 1 to len(::aIndexes)
        ::oCurrentIndex := ::aIndexes[nI]
        ::oCurrentIndex:Close()
        FreeObj(::oCurrentIndex)
    Next

Return

// ----------------------------------------------------------
// Cria um arquivo de dados na instancia atual usando a estrutura 
// do objeto de arquivo de dados informado como parametro 
// Pode ser infomado um Alias / WorkArea
// Caso lAppend seja .T., a tabela é aberta em modo exclusivo e para gravação 
// e os dados são importados

METHOD CreateFrom( _oDBF , lAppend  ) CLASS TIISAM
    Local lFromAlias := .F. 
    Local cAlias := ""
    Local aStruct := {}

    If lAppend = NIL ; lAppend := .F. ; Endif

    If valtype(_oDBF) == 'C'

        // Se a origem é caractere, só pode ser um ALIAS 
        lFromAlias := .T. 
        cAlias := alltrim(upper(_oDBF))
        If Select(cAlias) < 1 
            UserException("Alias does not exist - "+cAlias)
        Endif

        aStruct := (cAlias)->(DbStruct())
        
    Else

        aStruct := _oDBF:GetStruct()

    Endif

    If !::Create(aStruct)
        Return .F.
    Endif

    IF lAppend

        // Dados serão apendados na criação 
        // Abre para escrita exclusiva 
        
        If !::Open(.T.,.T.)
            Return .F.
        Endif

        // Apenda os dados	
        IF !::AppendFrom(_oDBF)
            Return .F.
        Endif

        // E posiciona no primeiro registro 	
        ::GoTop()
        
    Endif

Return .T.


// ----------------------------------------------------------
// Apena os dados da tabela informada na atual 
// Origem = _oDBF
// Destino = self

METHOD AppendFrom( _oDBF , lAll, lRest , cFor , cWhile ) CLASS TIISAM
    Local aFromTo := {}
    Local aFrom := {}
    Local nI, nPos, cField
    Local lFromAlias := .F. 
    Local cAlias := ""
    Local lExitVar := Valtype(lAbortPrint) == "L"
    Local nSegundos := Int(Seconds())

    DEFAULT lAll  := .T. 
    DEFAULT lRest := .F.
    DEFAULT cFor := ''
    DEFAULT cWhile := ''
                
    // Primeiro, a tabela tem qye estar aberta
    IF !::lOpened
        UserException("AppendFrom Failed - Table not opened")
        Return .F.
    Endif

    IF !::lCanWrite
        UserException("AppendFrom Failed - Table opened for READ ONLY")
        Return .F.
    Endif

    If valtype(_oDBF) == 'C'

        // Se a origem é caractere, só pode ser um ALIAS 
        lFromAlias := .T. 
        cAlias := alltrim(upper(_oDBF))
        If Select(cAlias) < 1 
            UserException("Alias does not exist - "+cAlias)
        Endif

        aFrom := (cAlias)->(DbStruct())
        
    Else

        aFrom := _oDBF:GetStruct()

    Endif

    // Determina match de campos da origem no destino 
    For nI := 1 to len(aFrom)
        cField :=  aFrom[nI][1]
        nPos := ::FieldPos(cField)
        If nPos > 0 
            aadd( aFromTo , { nI , nPos })
        Endif
    Next

    IF lFromAlias
        
        // Dados de origem a partir de uma WorkArea
        
        If lAll 
            // Se é para importar tudo, pega desde o primeiro registro 
            (cAlias)->(DbGoTop())
        Endif
        
        While !(cAlias)->(EOF())

            If ! IsBlind() .and. Int(Seconds()) - nSegundos > 3
                nSegundos := Int(Seconds())
                IncProc("Total de linhas geradas no Excel: " + AllTrim(Str(::Recno())))
                ProcessMessage()
            EndIf 

            If lExitVar .and. lAbortPrint
                Exit  
            EndIf

            // Insere um novo registro na tabela atual
            ::Insert()

            // Preenche os campos com os valores da origem
            For nI := 1 to len(aFromTo)
                ::FieldPut(  aFromTo[nI][2] , (cAlias)->(FieldGet(aFromTo[nI][1]))  )
            Next

            // Atualiza os valores
            ::Update()

            // Vai para o procimo registro
            (cAlias)->(DbSkip())

        Enddo
        
    Else
        
        If lAll 
            // Se é para importar tudo, pega desde o primeiro registro 
            _oDBF:GoTop()
        Endif
        
        While !_oDBF:EOF()

            // Insere um novo registro na tabela atual
            ::Insert()

            // Preenche os campos com os valores da origem
            For nI := 1 to len(aFromTo)
                ::FieldPut(  aFromTo[nI][2] , _oDBF:FieldGet(aFromTo[nI][1])  )
            Next

            // Atualiza os valores
            ::Update()

            // Vai para o procimo registro
            _oDBF:Skip()

        Enddo
        
    Endif

Return .T. 

// ----------------------------------------------------------
// Exporta o arquivo para um outro formato
// cFormat = Formato a exportar 
//    SDF
//    CSV 
//    JSON
//    XML
// cFileOut = Arquivo de saída 

METHOD Export( cFormat, cFileOut , bBlock ) CLASS TIISAM

    // Primeiro, a tabela tem qye estar aberta
    IF !::lOpened
        UserException("TIISAM:EXPORT() Failed - Table not opened")
        Return .F.
    Endif

    cFormat := alltrim(Upper(cFormat))

    If cFormat == "SDF" 
        lOk := ::_ExportSDF(cFileOut)	
    ElseIf cFormat == "CSV" 
        lOk := ::_ExportCSV(cFileOut)	
    ElseIf cFormat == "JSON" 
        lOk := ::_ExportJSON(cFileOut)
    ElseIf cFormat == "XML"
        lOk := ::_ExportXML(cFileOut)
    Else
        UserException("Export() ERROR - Formato ["+cFormat+"] não suportado. ")
    Endif

Return lOk


// ----------------------------------------------------------
// Recebe a definicao extendida da tabela 
// Com isso eu já tenho a estrutura 

METHOD SetFileDef(oDef)  CLASS TIISAM


    IF ::lOpened
        UserException("SetFileDef Failed - Table already opened")
        Return .F.
    Endif

    // Recebe a definição do arquivo 
    ::oFileDef := oDef

Return .T. 

// ----------------------------------------------------------
// Formato SDF
// Texto sem delimitador , Campos colocados na ordem da estrutura
// CRLF como separador de linhas
// Campo MEMO não é exportado

METHOD _ExportSDF( cFileOut ) CLASS TIISAM
    Local nHOut
    Local nPos
    Local cBuffer := ''
    Local cRow
    Local cTipo,nTam,nDec


    nHOut := fCreate(cFileOut)
    If nHOut == -1
        ::_SetError("Output SDF File Create Error - FERROR "+cValToChar(Ferror()))
        Return .F.
    Endif

    ::GoTop()

    While !::Eof()
        
        // Monta uma linha de dados
        cRow := ""
        
        For nPos := 1 TO ::nFldCount
            cTipo := ::aStruct[nPos][2]
            nTam  := ::aStruct[nPos][3]
            nDec  := ::aStruct[nPos][4]

            IF cTipo = 'M'
                Loop
            Endif

            If cTipo = 'C'
                cRow += ::FieldGet(nPos)
            ElseIf cTipo = 'N'
                cRow += Str(::FieldGet(nPos),nTam,nDec)
            ElseIf cTipo = 'D'
                cRow += DTOS(::FieldGet(nPos))
            ElseIf cTipo = 'L'
                cRow += IIF(::FieldGet(nPos),'T','F')
            Endif
        Next
        
        cRow += CRLF
        cBuffer += cRow
        
        If len(cBuffer) > 32000
            // A cada 32 mil bytes grava em disco
            fWrite(nHOut,cBuffer)
            cBuffer := ''
        Endif
        
        ::Skip()
        
    Enddo

    // Grava flag de EOF
    cBuffer += Chr(26)

    // Grava resto do buffer que falta
    fWrite(nHOut,cBuffer)
    cBuffer := ''

    fClose(nHOut)

Return

// ----------------------------------------------------------
// Formato CSV
// Strings entre aspas duplas, campos colocados na ordem da estrutura
// Virgula como separador de campos, CRLF separador de linhas 
// Gera o CSV com Header
// Campo MEMO não é exportado

METHOD _ExportCSV( cFileOut ) CLASS TIISAM
    Local nHOut
    Local nPos
    Local cBuffer := ''
    Local cRow
    Local cTipo,nTam,nDec
        

    nHOut := fCreate(cFileOut)
    If nHOut == -1
        ::_SetError("Output CSV File Create Error - FERROR "+cValToChar(Ferror()))
        Return .F.
    Endif

    // Primeira linha é o "header" com o nome dos campos 
    For nPos := 1 TO ::nFldCount
        If ::aStruct[nPos][2] == 'M'
            Loop
        Endif	
        If nPos > 1 
            cBuffer += ','
        Endif
        cBuffer += '"'+Alltrim(::aStruct[nPos][1])+'"'
    Next
    cBuffer += CRLF

    ::GoTop()

    While !::Eof()
        
        // Monta uma linha de dados
        cRow := ""
        
        For nPos := 1 TO ::nFldCount
            cTipo := ::aStruct[nPos][2]
            nTam  := ::aStruct[nPos][3]
            nDec  := ::aStruct[nPos][4]

            IF cTipo = 'M'
                Loop
            Endif

            If nPos > 1
                cRow += ","
            Endif
            
            If cTipo = 'C'
                // Dobra aspas duplas caso exista dentro do conteudo 
                cRow += '"' + StrTran(rTrim(::FieldGet(nPos)),'"','""') + '"'
            ElseIf cTipo = 'N'
                // Numero trimado 
                cRow += cValToChar(::FieldGet(nPos))
            ElseIf cTipo = 'D'
                // Data em formato AAAAMMDD entre aspas 
                cRow += '"'+Alltrim(DTOS(::FieldGet(nPos)))+'"'
            ElseIf cTipo = 'L'
                // Boooleano true ou false
                cRow += IIF(::FieldGet(nPos),'true','false')
            Endif
        Next
        
        cRow += CRLF
        cBuffer += cRow
        
        If len(cBuffer) > 32000
            // A cada 32 mil bytes grava em disco
            fWrite(nHOut,cBuffer)
            cBuffer := ''
        Endif
        
        ::Skip()
        
    Enddo

    // Grava resto do buffer que falta 
    If len(cBuffer) > 0 
        fWrite(nHOut,cBuffer)
        cBuffer := ''
    Endif

    fClose(nHOut)

Return .T. 


// ----------------------------------------------------------
// Formato JSON - Exporta estrutura e dados   
// Objeto com 2 propriedades 
// header : Array de Arrays, 4 colunas, estrutura da tabela
// data : Array de Arrays, cada linha é um registro da tabela, 
// campos na ordem da estrutura
// -- Campo Memo não é exportado 

/* 	{ 	
"header": [
	["cCampo", "cTipo", nTam, nDec], ...
],
"data": [
    ["José", 14, true], ...
] 	}
*/

METHOD _ExportJSON( cFileOut ) CLASS TIISAM
    Local nHOut
    Local nPos
    Local cBuffer := ''
    Local lFirst := .T.
    Local cRow
    Local cTipo,nTam,nDec


    nHOut := fCreate(cFileOut)
    If nHOut == -1
        ::_SetError("Output JSON File Create Error - FERROR "+cValToChar(Ferror()))
        Return .F.
    Endif


    cBuffer += '{' + CRLF
    cBuffer += '"header": [' + CRLF

    For nPos := 1 to len(::aStruct)
        If ::aStruct[nPos][2] == 'M'
            LOOP
        Endif
        If nPos = 1
            cBuffer += "["
        Else
            cBuffer += '],'+CRLF+'['
        Endif
        cBuffer += '"'+Alltrim(::aStruct[nPos][1])+'","'+;
        ::aStruct[nPos][2]+'",'+;
        cValToChar(::aStruct[nPos][3])+','+;
        cValToChar(::aStruct[nPos][4])
    Next

    cBuffer += ']'+CRLF
    cBuffer += ']' + CRLF
    cBuffer += ',' + CRLF
    cBuffer += '"data": [' + CRLF

    ::GoTop()

    While !::Eof()
        
        // Monta uma linha de dados
        if lFirst
            cRow := "["
            lFirst := .F.
        Else
            cRow := "],"+CRLF+"["
        Endif
        
        For nPos := 1 TO ::nFldCount

            cTipo := ::aStruct[nPos][2]
            nTam  := ::aStruct[nPos][3]
            nDec  := ::aStruct[nPos][4]

            IF cTipo = 'M'
                Loop
            Endif

            If nPos > 1
                cRow += ","
            Endif
            If cTipo = 'C'
                // Usa Escape sequence de conteudo
                // para astas duplas. --
                cRow += '"' + StrTran(rTrim(::FieldGet(nPos)),'"','\"') + '"'
            ElseIf cTipo = 'N'
                // Numero trimado
                cRow += cValToChar(::FieldGet(nPos))
            ElseIf cTipo = 'D'
                // Data em formato AAAAMMDD como string
                cRow += '"'+Alltrim(DTOS(::FieldGet(nPos)))+'"'
            ElseIf cTipo = 'L'
                // Boooleano = true ou false
                cRow += IIF(::FieldGet(nPos),'true','false')
            Endif
        Next
        
        cBuffer += cRow
        
        If len(cBuffer) > 32000
            // A cada 32 mil bytes grava em disco
            fWrite(nHOut,cBuffer)
            cBuffer := ''
        Endif
        
        ::Skip()
        
    Enddo

    // Termina o JSON
    cBuffer += ']' + CRLF
    cBuffer += ']' + CRLF
    cBuffer += '}' + CRLF

    // Grava o final do buffer
    fWrite(nHOut,cBuffer)
    cBuffer := ''

    // Fecha o Arquivo
    fClose(nHOut)

Return .T.


// ----------------------------------------------------------
// Formato XML - Exporta estrutura e dados   
// Objeto com 2 array de propriedades : header e data
// Para economizar espaço, as colunas de dados são nomeadas com as tags col1, col2 ... n

METHOD _ExportXML( cFileOut ) CLASS TIISAM
    Local nHOut
    Local nPos
    Local cBuffer := ''
    Local cRow
    Local cCampo,cTipo,nTam,nDec


    nHOut := fCreate(cFileOut)
    If nHOut == -1
        ::_SetError("Output XML File Create Error - FERROR "+cValToChar(Ferror()))
        Return .F.
    Endif

    cBuffer += '<?xml version="1.0" encoding="windows-1252" ?>' + CRLF
    cBuffer += '<table>' + CRLF

    cBuffer += '<header>' + CRLF

    For nPos := 1 to len(::aStruct)

        If ::aStruct[nPos][2] == 'M'
            LOOP
        Endif
                    
        cBuffer += '<field>'
        cBuffer += '<name>' +lower(Alltrim(::aStruct[nPos][1]))+ '</name>'
        cBuffer += '<type>' +::aStruct[nPos][2]+ '</type>'
        cBuffer += '<size>' +cValToChar(::aStruct[nPos][3])+ '</size>'
        cBuffer += '<decimal>' +cValToChar(::aStruct[nPos][4])+ '</decimal>'
        cBuffer += '</field>' + CRLF 
        
    Next

    cBuffer += '</header>' + CRLF
    cBuffer += '<data>' + CRLF

    ::GoTop()

    While !::Eof()
        
        // Monta uma linha de dados
        cRow := '<record id="'+cValToChar(::Recno())+'">'
        
        For nPos := 1 TO ::nFldCount
        
            cCampo := ::aStruct[nPos][1]
            cTipo  := ::aStruct[nPos][2]
            nTam   := ::aStruct[nPos][3]
            nDec   := ::aStruct[nPos][4]

            IF cTipo = 'M'
                Loop
            Endif

            cRow += '<'+lower(alltrim(cCampo))+'>'

            If cTipo = 'C'
                // Usa Escape sequence de conteudo
                // para aspas duplas. --
                cRow += StrTran(rTrim(::FieldGet(nPos)),'"','&quot;')
            ElseIf cTipo = 'N'
                // Numero trimado, com "." ponto deecimal 
                cRow += cValToChar(::FieldGet(nPos))
            ElseIf cTipo = 'D'
                // Data em formato AAAAMMDD 
                cRow += Alltrim(DTOS(::FieldGet(nPos)))
            ElseIf cTipo = 'L'
                // Boooleano = true ou false
                cRow += IIF(::FieldGet(nPos),'true','false')
            Endif

            cRow += '</'+lower(alltrim(cCampo))+'>'

        Next
        
        cRow += '</record>' + CRLF 

        cBuffer += cRow
        
        If len(cBuffer) > 32000
            // A cada 32 mil bytes grava em disco
            fWrite(nHOut,cBuffer)
            cBuffer := ''
        Endif
        
        ::Skip()
        
    Enddo

    // Termina o XML
    cBuffer += '</data>' + CRLF
    cBuffer += '</table>' + CRLF

    // Grava o final do buffer
    fWrite(nHOut,cBuffer)
    cBuffer := ''

    // Fecha o Arquivo
    fClose(nHOut)

Return .T.

// --------------------------------------------------------------------
// Importacao de dados de arquivo externo -- Formatos SDF,CDV e JSON   

METHOD Import(cFileIn,cFormat) CLASS TIISAM
    Local lOk

    // Primeiro, a tabela tem qye estar aberta
    IF !::lOpened
        UserException("Import Failed - Table not opened")
        Return .F.
    Endif

    IF !::lCanWrite
        UserException("Import Failed - Table opened for READ ONLY")
        Return .F.
    Endif

    // Ajusta formato 
    cFormat := alltrim(Upper(cFormat))

    If cFormat == "SDF"
        lOk := ::_ImportSDF(cFileIn)
    ElseIf 	cFormat == "CSV"
        lOk := ::_ImportCSV(cFileIn)
    ElseIf 	cFormat == "JSON"
        lOk := ::_ImportJSON(cFileIn)
    Else
        UserException("Export() ERROR - Formato ["+cFormat+"] não suportado. ")
    Endif

Return lOk 


// --------------------------------------------------------------------
// Importacao de arquivo SDF 
// A estrutura tem que ser a mesma que o arquivo foi gerado 
// Nao tengo como validar os campos, mas tenho como fazer uma consistencia 
// Baseado no tamanho de cada linha com a estrutura atual da tabela. 

METHOD _ImportSDF(cFileIn) CLASS TIISAM
    Local nH ,nFSize
    Local cOneRow := ''
    Local nRowSize := 0
    Local nRows := 0 
    Local nCheck 
    Local nOffset 
    Local cTipo, nTam, nPos
    Local cValue, xValue


    // Abre o arquivo SDF para leitura 
    nH := FOpen(cFileIn)

    If nH == -1
        ::_SetError( "_ImportSDF() ERROR - File Open Failed - FERROR "+cValToChar(ferror()) )
        Return .F. 
    Endif

    // Pega tamanho do arquivo no disco 
    nFSize := fSeek(nH,0,2)
    FSeek(nH,0)
            
    // Calcula o tamanho de cada linha baseado na estrutura
    For nPos := 1 TO ::nFldCount
        cTipo := ::aStruct[nPos][2]
        If cTipo = 'M' 
            // Ignora campos MEMO 
            LOOP
        Endif
        nTam  := ::aStruct[nPos][3]
        nRowSize += nTam
    Next

    // Cada linha do SDF deve ter o numero de bytes 
    // de acordo com a estrutura da tabela, mais CRLF 

    nRowSize += 2

    // O resto da divisao ( Modulo ) do tamanho do arquivo 
    // pelo tamanho da linha deve ser 1 -- devido 
    // ao ultimo byte (0x1A / Chr)26)) indicando EOF

    nCheck := nFsize % nRowSize

    If nCheck <> 1

        ::_SetError( "_ImportSDF() ERROR - SDF File Size FERROR MISMATCH" )
        FClose(nH)
        Return .F. 

    Endif

    // Calcula quantas linhas tem no arquivo 
    nRows :=  (nFsize-1) / nRowSize

    While nRows > 0 

        // Le uma linha do arquivo 
        fRead(nH,@cOneRow,nRowSize)
        
        // Insere nova linha em branco 
        ::Insert()

        // Le os valores de cOneRow
        nOffset := 1
        For nPos := 1 TO ::nFldCount

            cTipo := ::aStruct[nPos][2]
            
            If cTipo = 'M' 
                // Ignora campos MEMO 
                LOOP
            Endif
            
            nTam  := ::aStruct[nPos][3]

            cValue	:= substr(cOneRow,nOffset,nTam)
            nOffset += nTam
            
            If cTipo == "C"
                ::Fieldput(nPos,cValue)
            ElseIf cTipo == "N"
                xValue := Val(cValue)
                ::Fieldput(nPos,xValue)
            ElseIf cTipo == "D"
                xValue := STOD(cValue)
                ::Fieldput(nPos,xValue)
            ElseIf cTipo == "L"
                xValue := ( cValue = 'T' )
                ::Fieldput(nPos,xValue)
            Endif		

        Next
        
        ::Update()

        nRows--

    Enddo

    FClose(nH)

Return


// ----------------------------------------
// Importacao de arquivo CSV
// Calculo o tamanho maximo da linha baseado na estrutura da tabela 
// e passo a ler o arquivo em blocos, parseando o conteúdo lido em memória
// Comparo o Header com os campos da estrutura

METHOD _ImportCSV(cFileIn) CLASS TIISAM
    Local nH , nFSize
    Local cBuffer := '' , cTemp := ''
    Local nMaxSize := 0
    Local cValue , xValue
    Local cTipo, nTam, nPos
    Local nToRead 
    Local nLidos , nI
    Local aHeadCpos := {}
    Local aFileCpos := {}


    // Abre o arquivo CSV para leitura 
    nH := FOpen(cFileIn)

    If nH == -1
        ::_SetError( "_ImportCSV() ERROR - File Open Failed - FERROR "+cValToChar(ferror()) )
        Return .F. 
    Endif

    // Pega tamanho do arquivo no disco 
    nFSize := fSeek(nH,0,2)
    FSeek(nH,0)
            
    // Calcula o tamanho máximo de uma linha baseado na estrutura da tabela 
    For nPos := 1 TO ::nFldCount
        cCampo  := ::aStruct[nPos][1]
        cTipo := ::aStruct[nPos][2]
        
        If cTipo = 'M' 
            // Ignora campos MEMO 
            LOOP
        Endif
        nTam  := ::aStruct[nPos][3] 
        // Soma 3 ao tamanho de cada coluna
        // DElimitadores + separador 
        nMaxSize += ( nTam + 3 )

        // Monta a lista de campos baseado na estrutura atual 
        aadd(aFileCpos , alltrim(upper(cCampo)) )
    Next

    // Acrescenta um final de linha
    nMaxSize += 2

    // Le a primeira linha - HEader com os campos 
    // Logo de cara lê 512 bytes 

    nLidos := fRead(nH , @cBuffer , 512 )
    nFSize -= nLidos

    // Acha a quebra de linha e remove ela do buffer
    nPos := AT( CRLF , cBuffer )
    cOneRow := left(cBuffer , nPos-1)
    cBuffer := substr(cBuffer,nPos+2)

    // Cria array com os campos considerando a virgula como separador
    aHeader := StrTokArr(cOneRow,",")

    For nI := 1 to len(aHeader)
        cField := aHeader[nI]
        NoQuotes(@cField)

        // Monta a lista de campos baseado no header
        aadd(aHeadCpos, Alltrim(upper(cField)) )
    Next

    // Comparação de Arrays usando zCompare()
    // 0 = Conteúdos idênticos
    // < 0 = Diferentes ( -1 tipo , -2 conteudo ou -3 tamanho de array ) 

    If zCompare( aFileCpos , aHeadCpos ) < 0 
        fClose(nH)	
        ::_SetError( "_ImportCSV() ERROR - Header Fields Mismatch." )
        Return .F. 
    Endif

    // Uma linha deste arquivo NUNCA deve chegar em nMaxSize
    // Ele é calculado assumindo que todas as colunas tem delimitador 
    // e um separador, ele soma isso inclusive na ultima coluna 

    While nFSize > 0 .or. !empty(cBuffer)
        
        IF len(cBuffer) < nMaxSize .and. nFSize > 0 
            // SE o buffer em memoria 
            nToRead := MIN ( nMaxSize * 5 , nFSize ) 
            nLidos := fRead(nH , @cTemp , nToRead )
            cTemp := left(cTemp,nLidos)
            nFSize -= nLidos
            cBuffer += cTemp
        Endif	

        // Agora identifica uma linha e faz parser de conteudo 

        nPos := AT( CRLF , cBuffer )
        cOneRow := left(cBuffer , nPos-1)
        cBuffer := substr(cBuffer,nPos+2)
        
        // Insere nova linha em branco 
        ::Insert()

        For nPos := 1 to ::nFldCount
        
            cTipo := ::aStruct[nPos][2]
            nTam  := ::aStruct[nPos][3]

            If cTipo = 'M' 
                // Ignora campos MEMO 
                LOOP
            Endif

            // Pega procimo valor de campo e remove da linha 
            cValue := GetNextVal(@cOneRow)
            
            If cTipo == "C"
                // Tipo caractere, coloca valor direto 
                ::Fieldput(nPos,cValue)
            ElseIf cTipo == "N"
                // Numérico, converte para numero 
                xValue := Val(cValue)
                ::Fieldput(nPos,xValue)
            ElseIf cTipo == "D"
                // Data , string em formato AAAMMDD , converte para Data 
                xValue := STOD(cValue)
                ::Fieldput(nPos,xValue)
            ElseIf cTipo == "L"
                // Booleano , pode ser Y, T , 1 ou TRUE
                xValue := Upper(cValue)
                If xValue = 'Y' .or. xValue = 'T' .or. xValue = '1' .or. xValue = 'TRUE'
                    ::Fieldput(nPos,.T.)
                Endif
            Endif		

        Next
        
        ::Update()

    Enddo	

    FClose(nH)

Return

// ----------------------------------------

METHOD _ImportJSON(cFileIn) CLASS TIISAM
    UserException("TIISAM:_ImportJSON() NOT IMPLEMENTED.")
Return .F. 


// ----------------------------------------
// *** METODO DE USO INTERNO ***
// Verifica se o registro atual está contemplado pelo filtro 
// Release 20190106 -- Contempla filtro de registros deletados

METHOD _CheckFilter() CLASS TIISAM

    If ::lSetDeleted .AND. ::lDeleted
        // Filtro de deletados está ligado 
        // e este registro está deletado .. ignora
        Return .F. 
    Endif

    If ::bFilter != NIL 
        // Existe uma expressao de filtro 
        // Roda a expressão para saber se este registro 
        // deve estar  "Visivel" 
        Return Eval(::bFilter , self )	
    Endif

Return .T. 

// ----------------------------------------
// *** METODO DE USO INTERNO ***
// Le e posiciona no proximo registro, considerando filtro 

METHOD _SkipNext() CLASS TIISAM
    Local nNextRecno

    While (!::lEOF)

        If ::nIndexOrd > 0 
            // Se tem indice ativo, pergunta pro indice
            // qual é o próximo registro
            nNextRecno := ::oCurrentIndex:GetNextRec()
        Else
            // Estou na ordem fisica
            // Parte do registro atual , soma 1 
            nNextRecno := ::Recno() + 1 
        Endif
        
        // Retornou ZERO ou 
        // Passou do final de arquivo, esquece
        If nNextRecno == 0 .OR. nNextRecno > ::nLastRec
            ::lEOF := .T.
            ::_ClearRecord()
            Return .F. 
        Endif

        // ----------------------------------------
        // Atualiza o numero do registro atual 
        ::nRecno := nNextRecno

        // Traz o registro atual para a memória
        ::_ReadRecord()

        // Passou na checagem de filtro ? Tudo certo 
        // Senao , continua lendo ate achar um registro valido 
        If ::_CheckFilter()
            Return .T. 
        Endif

    Enddo

Return .F. 

// ----------------------------------------
// *** METODO DE USO INTERNO ***
// Le e posiciona no registro anmterior, considerando filtro 

METHOD _SkipPrev() CLASS TIISAM
    Local nPrevRecno

    While (!::lBOF)

        If ::nIndexOrd > 0 
            // Se tem indice ativo, pergunta pro indice
            // qual é o registro anterior
            nPrevRecno := ::oCurrentIndex:GetPrevRec()
        Else
            // Estou na ordem fisica
            // Parte do registro atual , subtrai 1
            nPrevRecno := ::Recno() - 1 
        Endif
        
        // Tentou ler antes do primeiro registro 
        // Bateu em BOF()
        If nPrevRecno < 1 
            ::lBOF := .T.
            Return .F. 
        Endif

        // ----------------------------------------
        // Atualiza o numero do registro atual 
        ::nRecno := nPrevRecno

        // Traz o registro atual para a memória
        ::_ReadRecord()

        // Passou na checagem de filtro ? Tudo certo 
        // Senao , continua lendo ate achar um registro valido 
        If ::_CheckFilter()
            Return .T. 
        Endif

    Enddo

    // Chegou no topo. 
    // Se tem filtro, e o registro nao entra no filtro, localiza 
    // o primeir registro válido 
    If ( !::_CheckFilter() )
        ::GoTop()
        ::lBOF := .T. 
    Endif

Return .F. 

// ----------------------------------------------------------
// Retorna apenas a descrição do ultimo erro 

METHOD GetErrorStr() CLASS TIISAM 
Return ::cError

// ----------------------------------------------------------
// *** METODO DE USO INTERNO ***
// Limpa o registro do ultimo erro 

METHOD _ResetError() CLASS TIISAM 
    ::cError := ''
Return

// ----------------------------------------------------------
// *** METODO DE USO INTERNO ***
// Seta uma nova ocorrencia de erro

METHOD _SetError(cErrorMsg) CLASS TIISAM 
    ::cError := cErrorMsg
Return


// ----------------------------------------------------------
// Permite setar o modo "verbose" da classe

METHOD SetVerbose( lSet ) CLASS TIISAM 
    ::lVerbose := lSet
Return

// ----------------------------------------------------------
// Retorna  .T. se o modo verbose está ligado 

METHOD IsVerbose() CLASS TIISAM 
Return ::lVerbose

// ----------------------------------------------------------
// Inicializa as propriedades da classe base

METHOD _InitVars() CLASS TIISAM 

    ::lOpened       := .F. 
    ::lCanWrite     := .F. 
    ::cError        := ''
    ::lVerbose      := .T. 
    ::bFilter       := NIL
    ::lBof          := .F. 
    ::lEof          := .F. 
    ::nIndexOrd     := 0
    ::aIndexes      := {}
    ::oCurrentIndex := NIL
    ::nLastRec      := 0
    ::aStruct       := {}
    ::nFldCount     := 0
    ::aGetRecord    := {}
    ::aPutRecord    := {}

Return


// ----------------------------------------------------------
// *** METODO DE USO INTERNO ***
// Limpa os campos do registro atual de leitura
// ( Inicializa todos com os valores DEFAULT ) 
// Limpa campos de gravação / update 
// ( seta NIL nos elementos ) 

METHOD _ClearRecord() CLASS TIISAM
    Local nI , cTipo , nTam


    // Inicializa com o valor default os campos da estrutura 
    For nI := 1 to ::nFldCount
        cTipo := ::aStruct[nI][2]
        nTam  := ::aStruct[nI][3]
        If cTipo == 'C'
            ::aGetRecord[nI] := space(nTam)
        ElseIf cTipo == 'N'
            ::aGetRecord[nI] := 0
        ElseIf cTipo == 'D'
            ::aGetRecord[nI] := ctod('')
        ElseIf cTipo == 'L'
            ::aGetRecord[nI] := .F.
        ElseIf cTipo == 'M'
            ::aGetRecord[nI] := 0
        Endif
    Next

    // Zera também registro de granação
    ::aPutRecord := Array(::nFldCount)

Return

// ----------------------------------------------------------
// Cria uma string para criar codeblock dinamico 
// baseado em expressao usando camposa da tabela
// Os campos devem estar em letras maiúsculas. Cada campo será 
// trocado por o:FieldGet(nPos), o codeblock deve ser usado 
// com Eval() passando como argumento o objeto da tabela 

METHOD _BuildFieldBlock(cFieldExpr) CLASS TIISAM
    Local aCampos := {}
    Local cBlockStr
    Local nI, nPos


    // Cria lista de campos
    aEval( ::aStruct , {|x| aadd(aCampos , x[1]) } )

    // Ordena pelos maiores campos primeiro
    aSort( aCampos ,,, {|x,y| alltrim(len(x)) > alltrim(len(y)) } )

    // Copia a expressao 
    cBlockStr := cFieldExpr

    // Troca os campos por o:Fieldget(nCpo)
    // Exemplo : CAMPO1 + CAMPO2 será trocado para o:FieldGet(1) + o:FieldGet(2)

    For nI := 1 to len(aCampos)
        cCampo := alltrim(aCampos[nI])
        nPos   := ::Fieldpos(cCampo)
        cBlockStr  := StrTran( cBlockStr , cCampo,"o:FieldGet(" +cValToChar(nPos)+ ")")
    Next

    // Monta a string com o codeblock para indice
    cBlockStr := "{|o| "+cBlockStr+"}"

Return cBlockStr

// Remove aspas duplas delimitadoras por referencia
// Retorna por referencia se a string estava 
// delimitada por aspas duplas 
STATIC Function NoQuotes(cQuotStr,lQuoted)
    lQuoted := left(cQuotStr,1) = '"' .and. right(cQuotStr,1) = '"'
    If lQuoted
        cQuotStr := Substr(cQuotStr,2,len(cQuotStr)-2)	
        cQuotStr := StrTran(cQuotStr,'""','"')
    Endif
Return 

// ----------------------------------------------------------

STATIC Function GetNextVal(cCSVLine)
    Local lQuoted := .F.
    Local lInAspas := .F.
    Local nI , nT := len(cCSVLine)
    Local cRet := ''

    If left(cCSVLine,1) == '"'
        lQuoted := .T.
    Endif

    For nI := 1 to nT
        cChar := substr(cCSVLine,nI,1)
        If cChar == ','
            IF lInAspas
                cRet += cChar
            Else
                cCSVLine := substr(cCSVLine,nI+1)
                EXIT
            Endif
        ElseIF cChar == '"'
            lInAspas := !lInAspas
            cRet += cChar
        Else
            cRet += cChar
        Endif
    Next

    IF  nI >  nT
        // Saou do loop sem achar o separador  ","
        // Logo, a linha acabou
        cCSVLine := ""
    Endif

    If lQuoted
        // Remove aspas antes e depois
        // Troca escape sequence de aspas [""] por ["]
        NoQuotes(@cRet)
    Endif

Return cRet

// ----------------------------------------------------------
// Busca um registro que atenda os criterios informados
// aRecord recebe os dados a procurar no formato [1] Campo [2][ Conteudo 
// aFound retorna o registro encontrado por referencia ( todos os campos ) 
// no mesmo formato do aRecord, acrescido do RECNO 
// Por padrao a busca é feita por substring 
// Caso seja especificada busca EXATA, os conteudos dos campos 
// informados devem ter correspondencia exata com a base de dados

METHOD Search(aRecord,aFound,lExact)  CLASS TIISAM 
    Local nCnt := len(aRecord)
    Local nI
    Local aFldPos := {}
    Local nFound := 0


    IF lExact = NIL
        lExact := .F.
    Endif

    aSize(aFound,0)

    // Sempre posiciona no topo 

    If nCnt <= 0 
        
        // Sem condições especificadas, pega 
        // o primeiro registro 
        ::GoTop()

    Else

        // Mapeia campos informados com a posição 
        // do campo no arquivo 	
        For nI := 1 to nCnt
            aadd( aFldPos , ::fieldpos(aRecord[nI][1]) )
        Next
        
        // Começa a busca sempre no inicio do arquivo 
        ::GoTop()

        // FAz busca sequencial	
        While !::Eof()
            nFound := 0 
            For nI := 1 to nCnt 
                IF lExact
                    // Busca exata
                    IF ::FieldGet(aFldPos[nI]) == aRecord[nI][2]
                        nFound++
                    Endif
                Else
                    // Busca por substring ( ou "like %content%" ) 
                    If alltrim(aRecord[nI][2]) $ ::FieldGet(aFldPos[nI])  
                        nFound++
                    Endif
                Endif
            Next
            If nFound == nCnt
                EXIT
            Endif
            ::Skip()
        Enddo
        
    Endif

    If !::Eof()  
        // Nao estou em EOF = achei um registro 
        For nI := 1 to ::nFldCount
            aadd(aFound , {  ::FieldName(nI) , ::FieldGet(nI)  })
        Next
        // Acrescenta o RECNO no campo
        aadd(aFound,{"RECNO",::Recno()})
        Return .T.
    Endif

    ::_SetError( "Nenhum registro foi encontrado baseado nos dados informados" )

Return .F. 


/* ==================================================

Classe      TIINDEX
Autor       Julio Wittwer
Data        05/01/2019
Descrição   A partir de um objeto TIISAM, permite 
            a criação de um índice em memória 

================================================== */

CLASS TIINDEX FROM LONGNAMECLASS

   DATA oDBF			// Objeto TIISAM relacionado ao índice 
   DATA cIndexExpr      // Expressão AdvPL original do índice
   DATA bIndexBlock     // CodeBlock para montar uma linha de dados do índice
   DATA aIndexData      // Array com os dados do índice ordenado pela chave 
   DATA nCurrentRow     // Numero da linha atual do índice 
   DATA lVerbose        // Modo Verbose (echo em console ligado)

   METHOD NEW(oDBF)     // Cria o objeto do índice
   METHOD CREATEINDEX(cIndexExpr) // Cria o índice baseado na chave fornecida 
   METHOD CLOSE()       // Fecha o índice e limpa os dados da memória 

   METHOD GetFirstRec() // Retorna o RECNO do primeiro registro do índice
   METHOD GetPrevRec()  // Retorna o RECNO do Registro anterior do índice
   METHOD GetNextRec()  // Retorna o RECNO do próximo registro do índice
   METHOD GetLastRec()  // Retorna o RECNO do último registro do índice 
   
   METHOD GetIndexExpr()  // Rertorna a expressão de indexação 
   METHOD GetIndexValue() // Retorna o valor da chave de indice do registro atual 
   METHOD GetIndexRecno() // REtorna o numero do RECNO da posição do índice atual 
   METHOD IndexSeek()     // Realiza uma busca ordenada por um valor informado 
   METHOD RecordSeek()    // REaliza uma busca no indice pelo RECNO 
   METHOD InsertKey()     // Insere uma nova chave no indice ao inserir um registro
   METHOD UpdateKey()     // Atualiza uma chave de indice ( em implementação ) 
   
   METHOD CheckSync()    // Verifica a necessidade de sincronizar o indice 
   METHOD SetVerbose()    // Seta modo verbose com echo em console ( em implementação 
   
ENDCLASS

// ----------------------------------------
// Construtor do indice em memoria
// Recebe o objeto da tabela

METHOD NEW(oDBF) CLASS TIINDEX
    ::oDBF := oDBF
    ::cIndexExpr := ''
    ::bIndexBlock := NIL
    ::aIndexData := {}
    ::nCurrentRow := 0
    ::lVerbose   := .T.
Return self

// ----------------------------------------
// Permite ligar ou desligar o modo verbose da classe de indice
METHOD SetVerbose( lSet ) CLASS TIINDEX
    ::lVerbose := lSet
Return


// ----------------------------------------
// *** METODO DE USO INTERNO ***
// Verifica se existe sincronismo pendente antes de fazer uma movimentacao
// Caso tenha, efetua o sincronismo da posicao do indice com a posicao do RECNO

METHOD CheckSync() CLASS TIINDEX
    Local nRecno

    If ::oDBF:Eof()
        // Nao posso sincronizar em EOF()
        Return
    Endif
        
    // Pega o numero do RECNO atual do DBF
    nRecno := ::oDBF:Recno()
        
    IF ::aIndexData[::nCurrentRow][2] != nRecno
        
        // Se o RECNO da posicao de indice nao está sincronizado,
        // Busca pela posicao correta do indice de addos ordenados
        // correspondente ao RECNO atual
        
        ::nCurrentRow := ::RecordSeek(nRecno)
        
        If ::nCurrentRow <= 0
            UserException("*** INDEX RESYNC FAILED - RECNO "+cValToChar(nRecno)+" ***")
        Endif
        
    Endif

Return

// ----------------------------------------
// Cria um indice na memoria usando a expressao
// enviada como parametro

METHOD CREATEINDEX( cIndexExpr ) CLASS TIINDEX
    Local cIndexBlk

    // Guarda a expressão original do indice
    ::cIndexExpr := cIndexExpr

    // Monta o CodeBlock para a montagem da linha de dados
    // com a chave de indice
    cIndexBlk := ::oDbf:_BuildFieldBlock( cIndexExpr )

    // Faz a macro da Expressao
    ::bIndexBlock := &(cIndexBlk)

    // Agora varre a tabela montando o o set de dados para criar o índice
    ::aIndexData := {}

    // Coloca a tabela em ordem de regisrtros para a criação do indice
    ::oDBF:SetOrder(0)
    ::oDBF:ClearFilter()
    ::oDBF:GoTop()

    While !::oDBF:Eof()
        // Array de dados
        // [1] Chave do indice
        // [2] RECNO
        aadd( ::aIndexData , { Eval( ::bIndexBlock , ::oDBF ) , ::oDBF:Recno() } )
        ::oDBF:Skip()
    Enddo

    // Sorteia pela chave de indice, usando o RECNO como criterio de desempate
    // Duas chaves iguais, prevalesce a ordem fisica ( o menor recno vem primeiro )
    aSort( ::aIndexData ,,, { |x,y| ( x[1] < y[1] ) .OR. ( x[1] == y[1] .AND. x[2] < y[2] ) } )

Return .T.

// ----------------------------------------
// Retorna o primeiro RECNO da ordem atual
// Caso nao tenha dados, retorna zero

METHOD GetFirstRec() CLASS TIINDEX
    If Len(::aIndexData) > 0
        ::nCurrentRow := 1
        Return ::aIndexData[::nCurrentRow][2]
    Endif
Return 0

// ----------------------------------------
// Retorna o RECNO anterior da ordem atual
// Caso já esieta no primeiro registro ou
// nao tenha dados, retorna zero

METHOD GetPrevRec() CLASS TIINDEX
    If Len(::aIndexData) > 0 .and. ::nCurrentRow > 1
        ::CheckSync()
        ::nCurrentRow--
        Return ::aIndexData[::nCurrentRow][2]
    Endif
Return 0

// ----------------------------------------
// Retorna o próximo RECNO da ordem atual
// Caso nao tenha dados ou tenha chego em EOF
// retorna zero

METHOD GetNextRec() CLASS TIINDEX
    If ::nCurrentRow < Len(::aIndexData)
        ::CheckSync()
        ::nCurrentRow++
        Return ::aIndexData[::nCurrentRow][2]
    Endif
Return 0

// ----------------------------------------
// Retorna o numero do ultimo RECNO da ordem atual
// Caso nao tenha dados retorna zero

METHOD GetLastRec() CLASS TIINDEX
    If Len(::aIndexData) > 0
        ::nCurrentRow := Len(::aIndexData)
        Return ::aIndexData[::nCurrentRow][2]
    Endif
Return 0

// ----------------------------------------
// Retorna a expressao de indice original
METHOD GetIndexExpr() CLASS TIINDEX
Return ::cIndexExpr

// ----------------------------------------
// REtorna o valor da chave de indice do registro atual
// Que a tabela esta posicionada
// Em AdvPL, seria o equivalente a &(Indexkey())

METHOD GetIndexValue() CLASS TIINDEX
Return Eval( ::bIndexBlock , ::oDBF )

// ----------------------------------------
// REtorna o numero do RECNO da posição de indice atual

METHOD GetIndexRecno() CLASS TIINDEX
Return ::aIndexData[::nCurrentRow][2]


// ----------------------------------------
// Um registro do dbf foi inserido 
// Preciso inserir uma nova chave no indice 
METHOD InsertKey() CLASS TIINDEX
    Local cKeyDBF, nRecDBF
    Local nTop := 1
    Local nBottom := Len(::aIndexData)
    Local nPos

    // Valores da chave atual do DBF 
    cKeyDBF := ::GetIndexValue()
    nRecDBF := ::oDBF:Recno()

    // Busca a posição correta para inserir a chave
    For nPos := nTop to nBottom
        if ( cKeyDBF >= ::aIndexData[nPos][1])
        LOOP
        Endif
    Next

    // aIndexData
    // [1] Chave de ordenação 
    // [2] Numero do recno 

    If nPos > nBottom
        // Nova chave acrescentada no final
        aadd(::aIndexData , { cKeyDBF, nRecDBF , nPos } )
    Else
    // Nova chave acrescentada na ordem 
        aadd(::aIndexData,NIL)
        aIns(::aIndexData,nPos)
        ::aIndexData[nPos] :=  { cKeyDBF, nRecDBF , nPos} 
    Endif

    // Atualiza  Posicao atual do indice 
    ::nCurrentRow := nPos

Return

// ----------------------------------------
// Um registro do dbf foi alterado.
// Preciso ver se houve alteração nos valores dos campos chave de indice
// Caso tenha havido, preciso remover a antiga e inserir a nova
// na ordem certa.

METHOD UpdateKey() CLASS TIINDEX
    Local cKeyDBF, nRecDBF
    Local cKeyIndex , nRecIndex
    Local nPos

    // Valores da chave atual do registro no DBF
    cKeyDBF := ::GetIndexValue()
    nRecDBF := ::oDBF:Recno()

    // Valores da chave atual do indice
    cKeyIndex := ::aIndexData[::nCurrentRow][1]
    nRecIndex := ::aIndexData[::nCurrentRow][2]

    IF nRecDBF == nRecIndex
        IF cKeyDBF == cKeyIndex
            // Nenhum campo chave alterado
            // Nada para fazer
            Return
        Endif
    Endif

    // Demove o elemento atual do array de indices
    aDel(::aIndexData,::nCurrentRow)

    // Acrescenta na ordem certa 
    For nPos := 1 to len(::aIndexData)-1
        If cKeyDBF > ::aIndexData[nPos][1]
            LOOP
        Endif
        If cKeyDBF == ::aIndexData[nPos][1]
            IF nRecDBF > ::aIndexData[nPos][2]
                LOOP
            Endif
        Endif
        EXIT
    Next

    // Insere na posição correta
    aIns(::aIndexData,nPos)
    ::aIndexData[nPos] := { cKeyDBF , nRecDBF }
    ::nCurrentRow := nPos

Return

// ----------------------------------------
// Realiza uma busca exata pela chave de indice informada

METHOD IndexSeek(cSeekKey) CLASS TIINDEX
    Local nTop := 1
    Local nBottom := Len(::aIndexData)
    Local nMiddle
    Local lFound := .F.

    If nBottom > 0
        
        If cSeekKey < ::aIndexData[nTop][1]
            // Chave de busca é menor que a primeira chave do indice
            Return 0
        Endif
        
        If cSeekKey > ::aIndexData[nBottom][1]
            // Chave de busca é maior que a última chave
            Return 0
        Endif
        
        While nBottom >= nTop
            
            // Procura o meio dos dados ordenados
            nMiddle := Int( ( nTop + nBottom ) / 2 )
            
            If ::aIndexData[nMiddle][1] = cSeekKey
                // Operador de igualdade ao comparar a chave do indice
                // com a chave informada para Busca. O Advpl opr default
                // considera que ambas sao iguais mesmo que a chave de busca
                // seja menor, desde que os caracteres iniciais até o tamanho da
                // chave de busca sejam iguais.
                lFound := .T.
                EXIT
            ElseIf cSeekKey < ::aIndexData[nMiddle][1]
                // Chave menor, desconsidera daqui pra baixo
                nBottom := nMiddle-1
            ElseIf cSeekKey > ::aIndexData[nMiddle][1]
                // Chave maior, desconsidera daqui pra cima
                nTop := nMiddle+1
            Endif
            
        Enddo
        
        If lFound
            
            // Ao encontrar uma chave, busca pelo menor RECNO
            // entre chaves repetidas, do ponto atual para cima
            // enquanto a chave de busca for a mesma.
            // Compara sempre a chave do indice com a chave de busca
            // com igualdade simples
            
            While ::aIndexData[nMiddle][1] = cSeekKey
                nMiddle--
                If nMiddle == 0
                    EXIT
                Endif
            Enddo
            
            // A posicao encontrada é a próxima, onde a
            // chave ainda era igual
            ::nCurrentRow := nMiddle+1
            
            // Retorna o RECNO correspondente a esta chave
            Return ::aIndexData[::nCurrentRow][2]
            
        Endif
        
    Endif

Return 0

// ----------------------------------------
// Retorna a posicao do array de indice 
// que contem este registro
METHOD RecordSeek(nRecno) CLASS TIINDEX
Return ascan(::aIndexData , {|x| x[2] == nRecno })

// ----------------------------------------
// Fecha o indice aberto
// limpa flags e dados da memoria
METHOD CLOSE() CLASS TIINDEX
    ::oDBF := NIL
    ::cIndexExpr := ''
    ::bIndexBlock := NIL
    ::nCurrentRow := 0
    ::lSetResync := .F.

    // Zera o array do indice
    aSize( ::aIndexData,0 )
Return



// funcoes staticas
// ################################################################################################################################
// ################################################################################################################################
// ################################################################################################################################
// ################################################################################################################################
// ------------------------------------------------------------

// Converte buffer de 4 bytes ( 32 Bits ) Big-Endian
// ( high bit first ) no seu valor numerico  
STATIC Function Bin4toN(cBin4)
    Local nByte1,nByte2,nByte3,nByte4
    Local nResult := 0

    nByte1 := asc(substr(cBin4,1,1))
    nByte2 := asc(substr(cBin4,2,1))
    nByte3 := asc(substr(cBin4,3,1))
    nByte4 := asc(substr(cBin4,4,1))

    nResult += ( nByte1 * 16777216 )
    nResult += ( nByte2 * 65536 )
    nResult += ( nByte3 * 256 )
    nResult += nByte4

Return nResult


// ------------------------------------------------------------
// Converte valor numérico em buffer de 4 bytes ( 32 Bits ) 
// ( High Byte First )
STATIC Function NtoBin4(nNum)
    Local cBin4 := '' , nTmp

    While nNum > 0
        nTmp := nNum % 256 
        cBin4 := chr(nTmp) + cBin4
        nNum := ( ( nNum - nTmp ) / 256 )
    Enddo
    While len(cBin4) < 4
        cBin4 := CHR(0) + cBin4
    Enddo
Return cBin4


// ------------------------------------------------------------
// Converte buffer de 2 bytes ( 16 Bits ) no seu valor numerico  
// ( High Byte First ) 
STATIC Function Bin2toN(cBin4)
    Local nByte1,nByte2

    nByte1 := asc(substr(cBin4,1,1))
    nByte2 := asc(substr(cBin4,2,1))

    If nByte1 > 0
        nByte2 += ( nByte1 * 256 )
    Endif

Return nByte2


// ------------------------------------------------------------
// Converte valor numérico (base 10 ) em buffer de 2 bytes ( 16 Bits ) 
// ( High Byte First ) 
STATIC Function NtoBin2(nNum)
    Local nL := ( nNum % 256 ) 
    Local nH := ( nNum-nL ) / 256 
Return chr(nH) + chr(nL)
                  

STATIC __aHEX := {'0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'}

STATIC Function DEC2HEX(nByte)
    Local nL := ( nByte % 16 )
    Local nH := ( nByte-nL) / 16
Return __aHEX[nH+1]+__aHEX[nL+1]
