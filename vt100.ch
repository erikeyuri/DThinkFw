#ifdef SPANISH
	#define STR0001 "Consulta F3"
	#define STR0002 "Control de inatividad activado, el terminal se desconectara en 1 minuto. Presione una tecla para interrumpir"
	#define STR0003 "Atencion"
	#define STR0004 "Aviso"
	#define STR0005 "Desconectado por el administrador"
	#define STR0006 "Simulador VT100"
	#define STR0007 "Activar"
	#define STR0008 "Desactivar"
	#define STR0009 "Espacio"
	#define STR0010 "Salida Paralela"
	#define STR0011 "Salida Serial"
#else
	#ifdef ENGLISH
		#define STR0001 "Consulta F3"
		#define STR0002 "Controle de inatividade ativado, o terminal irá se desconectar em 1 minuto. Pressione uma tecla para interromper"
		#define STR0003 "Atenção"
		#define STR0004 "Aviso"
		#define STR0005 "Desconectado pelo administrador"
		#define STR0006 "Simulador VT100"
		#define STR0007 "Ativar"
		#define STR0008 "Desativar"
		#define STR0009 "Espaco"
		#define STR0010 "Saida Paralela"
		#define STR0011 "Saida Serial"
	#else
		#define STR0001  "Consulta F3"
		Static STR0002 := "Controle de inatividade ativado, o terminal irá se desconectar em 1 minuto. Pressione uma tecla para interromper"
		#define STR0003  "Atenção"
		#define STR0004  "Aviso"
		#define STR0005  "Desconectado pelo administrador"
		Static STR0006 := "Simulador VT100"
		Static STR0007 := "Ativar"
		Static STR0008 := "Desativar"
		Static STR0009 := "Espaco"
		Static STR0010 := "Saida Paralela"
		Static STR0011 := "Saida Serial"
	#endif
#endif

#ifndef SPANISH
#ifndef ENGLISH
	STATIC uInit := __InitFun()

	Static Function __InitFun()
	uInit := Nil
	If Type('cPaisLoc') == 'C'

		If cPaisLoc == "PTG"
			STR0002 := "Controlo de inactividade activado, o terminal irá desconectar-se em 1 minuto. pressionar uma tecla para interromper"
			STR0006 := "Simulador Vt100"
			STR0007 := "Activar"
			STR0008 := "Desactivar"
			STR0009 := "Espaço"
			STR0010 := "Saída Paralela"
			STR0011 := "Saída Serial"
		EndIf
		EndIf
	Return Nil
#ENDIF
#ENDIF
