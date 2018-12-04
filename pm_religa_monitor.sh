#!/bin/ksh
#***************************************************************************************************
# ==============================================================================================
# Description: 	Monitor de arquivos do religa
# Version: 		1.0
# Company: 		Accenture do Brasil
# Author: 		Paulo Stracci
# =============================================================================================================================
# Variaveis - Processo
# =============================================================================================================================

AuxDate=`date +%Y%m%d%H%M%S`
ProcessName="pm_religa_monitor"
CFGFile="pm_religa_monitor.cfg"
LOGFile=$ProcessName"_"$AuxDate".log"
LogFileSQL=$ProcessName"_"$AuxDate
LOGErr="ERRO.err"
auxDateStart=`date +"%Y%m%d%H%M%S"`

# ===================================================================================================
# Variables - Connection
# ===================================================================================================
DBUSER=`grep USERNAME $CFGFile | cut -d: -f2`
DATABASE=`grep DATABASE $CFGFile | cut -d= -f2`
BSCSPASSWD=`grep DBPASSWD $CFGFile | cut -d: -f2`
# ===================================================================================================
# Variables - Directories
# ===================================================================================================
DIR_APP=`grep DIR_APP $CFGFile | cut -d: -f2`
DIR_LOG=`grep DIR_LOG $CFGFile | cut -d: -f2`
DIR_REL=`grep DIR_REL $CFGFile | cut -d: -f2`
VPARALLEL=`grep VPARALLEL $CFGFile | cut -d: -f2`
# ===================================================================================================
# Variables - Processo
# ===================================================================================================
# =============================================================================================================================
# Function AddOutput: Funcao que insere informações no LOG e na saída
# =============================================================================================================================

AddOutput () {	
	
	if [ $# -eq 2 ] && [ $2 -eq 1 ]; then	
		
		#Printa na tela e no LOG
		echo "["`date "+%d/%m/%Y %H:%M:%S"`"] - $1"
		echo "["`date "+%d/%m/%Y %H:%M:%S"`"] - $1">>$DIR_LOG/$LOGFile
		
	else
		
		#Printa na tela
		echo "["`date "+%d/%m/%Y %H:%M:%S"`"] - $1"
		
	fi
}
# ===================================================================================================
# Function Header
# ===================================================================================================
Header () {
AddOutput "-------------------------------------------------------------------------------" 1
AddOutput "ACCENTURE DO BRASIL -----------------------------------------------------------" 1
AddOutput "Processo de Análise de LOG RPCC -----------------------------------------------" 1
AddOutput "Version 1.0  ------------------------------------------------------------------" 1
AddOutput "-------------------------------------------------------------------------------" 1
AddOutput "Processo Iniciado -------------------------------------------------------------" 1
AddOutput "---------------	----------------------------------------------------------------" 1
AddOutput "Parametros da Base ------------------------------------------------------------" 1
AddOutput "USERNAME       : $DBUSER" 1
AddOutput "DATABASE       : $DATABASE" 1
AddOutput "-------------------------------------------------------------------------------" 1
AddOutput "Parametros de Diretorio --------------------------------------------------------" 1
AddOutput "DIR_APP      : $DIR_APP" 1
AddOutput "DIR_REL       : $DIR_REL" 1
AddOutput "DIR_LOG      : $DIR_LOG" 1
AddOutput "-------------------------------------------------------------------------------" 1
AddOutput "Parametros do Processo --------------------------------------------------------" 1
AddOutput "-------------------------------------------------------------------------------" 1
AddOutput "PARALLEL     : $VPARALLEL" 1
AddOutput "-------------------------------------------------------------------------------" 1
}

# =============================================================================================================================
# Function CleanExec: Funcao exclui arquivos para um nova execucao do processo
# =============================================================================================================================

CleanExec () {	

	#Exclui o arquivo "TmpTable.tmp" caso o mesmo exista
	if [ -f *".tmp" ]; then
		
		rm -f *".tmp"
	
	fi
	
	#Exclui os arquivos ".CTRL" caso os mesmos existam
	if [ -f $DIR_APP/$ProcessName*".CTRL" ]; then
		
		rm -f $DIR_APP/$ProcessName*".CTRL"
	
	fi	

	#Exclui os arquivos ".err" caso os mesmos existam
	if [ -f $LOGErr ]; then
		
		rm -f $LOGErr
	
	fi	
	
}
# ===================================================================================================
# Function ValidateParameters: Função de validação do preenchimento dos parâmetros de entrada
# ===================================================================================================
ValidateParameters () {
	
	AddOutput "Validando parametros" 1
	
if [ -z "$DIR_APP" ]; then
  echo "Error!!! Environment variable DIR_APP not defined or wrong"
  exit 1
fi

if [ -z "$DIR_LOG" ]; then
  echo "Error!!! Environment variable DIR_LOG not defined or wrong"
  exit 1
fi
if [ -z "$DBUSER" ]; then
  echo "Error!!! Environment variable USERNAME not defined or wrong"
  exit 1
fi
if [ -z "$DATABASE" ]; then
  echo "Error!!! Environment variable DATABASE not defined or wrong"
  exit 1
fi
if [ -z "$BSCSPASSWD" ]; then
  echo "Error!!! User $DBUSER is not defined in BSCSPASSWD environment variable"
  exit 1
fi

if [ -z "$VPARALLEL" ]; then
  echo "Error!!! Environment variable not defined in VPARALLEL environment variable"
  exit 1
fi
}

# =============================================================================================================================
# Function AddSeparador: Funcao que insere texto separado por duas fileiras de "="
# =============================================================================================================================

AddSeparador () {
	AddOutput "==================================================================================================" 1
	AddOutput "$1" 1
	AddOutput "==================================================================================================" 1
}

# =============================================================================================================================
# Function AddParam: Funcao que separa os parametros passados para execucao de scripts
# =============================================================================================================================

AddParam() {

  PARAME=""
  
  i=0
  
  for f in "$@"
  do
  	i=`expr $i + 1`
   	if [ $i -gt 4 ]; then
   		
 		PARAME=$PARAME" "'"'$f'"'

 		fi	
  done
    
}


# =============================================================================================================================
# Function Move_Files_To_LOG: Funcao que move arquivos gerados no processo para o diretorio de LOG
# =============================================================================================================================

Move_Files_To_LOG() {

  AddOutput "Movendo arquivos de LOG" 1
	
  	#cd $DIR_UTL
  	
  	#Move todos os arquivos com a mascara configurada .LOG do diretorio de UTL para o diretorio LOG
  	for arqX in $ProcessName*.log
  	do
  	  if [ -z "$arqX" ]; then		
  	  	   		
  	  	AddOutput "Nao existem arquivos para mover para o diretorio $DIR_LOG" 0
  	  	break
  	  	   		
  	  fi 
  	  if [ "$arqX" = $ProcessName"*.log" ]; then
  	    			
  	  	AddOutput "Nao existem arquivos para mover para o diretorio $DIR_LOG" 0
  	  	break
  	    			
  	  fi			    
  	  		
  	  #AddOutput "Movendo arquivo $arqX" 0
          
      mv -f $arqX $DIR_LOG
  
  	done
  
  cd $DIR_APP

}

# =============================================================================================================================
# Function SQL: Funcao que executa os scripts SQL com ou sem instancias
# =============================================================================================================================

SQL () {

	SQLNAME=$1
	USER=$2
	PASSWD=$3
	BASE=$4             
	

	if [ "$MULTINST" = "S" ]; then
	  
	  INST=$5
	  PARAME="$INST $PARAME"
		SQLTmp=$SQLNAME"_"$INST.CTRL
		
	else
		AddOutput "Script $SQLNAME" 1
		SQLTmp=$SQLNAME".CTRL"
		AddParam $@
	fi
	
	#OBS: Em execucao multinstancias declarar variaveis no SQL na seguinte ordem: 1º) Instancia, 2º)UTL, etc
	
	`sqlplus -s $USER/$PASSWD@$BASE @"$SQLNAME".sql $PARAME << ENDBLOCK >> $SQLTmp
	ENDBLOCK`
  ERROR_SQL1=$?
  ERROR_SQL2=`grep "Erro" $SQLTmp | wc -l`
  ERROR_SQL_E=`expr $ERROR_SQL1 + $ERROR_SQL2`
  
  if [ $ERROR_SQL_E != 0 ]; then

		if [ "$MULTINST" = "S" ]; then

			AddOutput "ERRO na Instancia $5: Ocorreu um falha na execucao do script $SQLNAME.sql - Verificar LOG do script e o LOG temporario: $DIR_LOG/$SQLTmp" 1
			echo "ERRO">>"abort_process.txt"
			#Move_Files_To_LOG
			exit 1
	
		else

			AddOutput "ERRO: Ocorreu um falha na execucao do script $SQLNAME.sql - Verificar LOG do script e o LOG temporario: $DIR_LOG/$SQLTmp" 1
			AddOutput "Processamento Abortado!" 1
			#mv -f $SQLTmp $DIR_LOG
			#Move_Files_To_LOG
			AddSeparador "Processo finalizado com erro. Verifique os LOGs do processo." 0
			exit 1

	  fi

	else

	if [ "$MULTINST" = "S" ]; then

 			AddOutput "Instancia $5 concluida com sucesso" 1
  	else

  		AddOutput "Script concluido com sucesso" 1
  	fi

		rm -f $SQLTmp

	fi

}



# =============================================================================================================================
# Function ExecSQL: Funcao que verifica o tipo de execucao dos scripts SQL
# =============================================================================================================================

ExecSQL () {

	cd $DIR_APP

	if [ "$MULTINST" = "S" ]; then

  	# Function de controle de arquivos para execução em multi instancias
  	AddOutput "Script $1" 1

		SESSION=0
		N_INSTANCES=$INSTANCIAS

		AddParam $@

		while [ $SESSION -lt $N_INSTANCES ];
		do
			sleep 3
			
			SESSION=`expr $SESSION + 1`

			AddOutput "Iniciando instancia $SESSION" 1
			
 			SQL $1 $2 $3 $4 $SESSION $PARAME &

		done

  	AddOutput "Processando..." 1
	sleep 3
	
	#Verifica instancias com erro
	if [ -e $DIR_APP/abort_process.txt ]; then

		INST_ERR=`grep "ERRO" "abort_process.txt" | wc -l`
		if [ $INST_ERR -ge $N_INSTANCES ]; then
  	
			AddOutput "Processamento Abortado!" 1
  			#Move_Files_To_LOG
			AddSeparador "Processo finalizado com erro em todas as instancias. Verifique os LOGs do processo." 0
			rm -f "abort_process.txt"
	  		exit 1

	  fi

	fi

  	AddOutput "Processamento liberado" 1

	else
		SQL $@
	fi

}

# =============================================================================================================================
# Function AbortProcess: Funcao para abortar o processamento
# =============================================================================================================================

AbortProcess () {
 
#Exclui os arquivos ".CTRL" caso os mesmos existam
if [ ! -f $DIR_LOG/$ProcessName*".CTRL" ]; then
	
	 AddOutput "Abortando Processamento..." 1
 	 echo "Processamento Abortado:" $AuxDate >> $AbortFile

	 #Move_Files_To_LOG

	 exit 1
	
fi 

}

# =============================================================================================================================
# Processo responsável pela monitoração do religa
# =============================================================================================================================

Principal() {


	cd $DIR_APP
	
	CONTADOR=0
	
	while [  $CONTADOR -lt 5 ]; do

	
		AddOutput "Aguardando arquivo RMCA_RPCC_REL... " 1
		
				
		#RMCA_RPCC_REL*.OLD
		for i  in  $(ls $DIR_REL/RMCA_RPCC_REL_*.TXT.OLD | cut -d '/' -f6 ); do
		
			qtd=`sqlplus -s $DBUSER/$BSCSPASSWD@$DATABASE << ENDBLOCK
			
			SET FEEDBACK OFF
			SET LINESIZE 100
			WHENEVER SQLERROR EXIT FAILURE;
			SET LINES 150;
			SET PAGES 0;
			SET HEAD OFF;
			SET SCAN OFF;
			SET ECHO OFF;
			SET SERVEROUTPUT ON SIZE 10000;
			
			ALTER SESSION ADVISE ROLLBACK;
			WHENEVER OSERROR EXIT SQL.OSCODE ROLLBACK
			WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK
			SET ECHO OFF
			SET VERIFY OFF
			SET FEEDBACK OFF
			SET SERVEROUTPUT ON SIZE 1000000
			SET TERMOUT ON
			
			SELECT /*+ PARALLEL (A, 8)*/ COUNT (*) FROM RP.ANALISE_RELIGA_CLI_CONTROLE A WHERE arq = '$i';
ENDBLOCK`;
						
			if [ $qtd -eq 0 ]; then
			
				AddOutput "Processando o arquivo $i..." 1
				
				cd $DIR_REL
				
				cp $i $DIR_APP
				
				cd $DIR_APP
				
				MULTINST="N"
				
				sqlldr $DBUSER/$BSCSPASSWD@$DATABASE control=pm_religa_monitor.ctl data=$i
				wait
				
				AddOutput "Arquivo arquivo $i carregado em tabela." 1
				
				sqlplus -s $DBUSER/$BSCSPASSWD@$DATABASE << ENDBLOCK
							
							INSERT INTO ANALISE_RELIGA_CLI_ARQ 
							SELECT /*+ PARALLEL (8)*/ '$i' arq, a.*, to_date (SUBSTR('$i', 15, 14 ), 'YYYYMMDDHH24MISS') as datahora, b.cod_status, c.dsc_status  
								FROM ANALISE_RELIGA_CLI a, acc_rpcc_registro b, acc_rpcc_status c
								WHERE a.customer_id = b.customer_id
								AND b.cod_status = c.cod_status;
							COMMIT;
							INSERT INTO RP.ANALISE_RELIGA_CLI_CONTROLE (ARQ) VALUES ('$i');
							COMMIT;
			
ENDBLOCK

				AddOutput "Arquivo $i inserindo na tabela de controle." 1
				rm $i
				mv *.bad $DIR_LOG

			fi
		done

		AddOutput "Aguardando arquivos... " 1
		
			mv *.log $DIR_LOG
		
		sleep 3600
		
	done

	#AddOutput "Iniciado Criação das Tabelas... " 1

	#MULTINST="N"
	#ExecSQL "pm_religa_monitor" $DBUSER $BSCSPASSWD $DATABASE $VPARALLEL $arq_name
	#wait
	

	
	AddOutput "Script finalizado...; " 1
}

# =============================================================================================================================
# Validacoes de Inicializacao
# =============================================================================================================================

# Limpa arquivos do processo (.tmp, .err, etc) de execucoes anteriores
CleanExec
# Validando parametros do arquivo de configuracao
ValidateParameters
# Escreve Header

Header

# =============================================================================================================================
# Processo Principal
# =============================================================================================================================

	MULTINST="N"

	echo "CTRL" >> $DIR_LOG/$ProcessName".CTRL"

	AddOutput "Iniciando Monitor." 1
	
	#Gera arquivos para processamento
	Principal
	
	AddOutput "Finalizando o processo" 1

	## =============================================================================================================================
	## Move os arquivos de LOG para os diretórios configurados
	## OBS: Enviar parametro orbigatorio "Y" - Cria subpastas com a data da execucao / "N" - Move arquivos pra raiz do diretorio
	## =============================================================================================================================
	
	if [ -e $DIR_APP/$LOGErr ]; then
	rm -f $LOGErr
	
	#Move_Files_To_LOG
	
	AddOutput "===================================================================================" 1
	AddOutput "Processo finalizado com algum tipo de erro. Verifique os LOGs do processo. " 1 
	AddOutput "===================================================================================" 1
	
	exit 1
	
	else
	
	#Move_Files_To_LOG
	
	AddOutput "====================================================================================" 1
	AddOutput "Processo finalizado com sucesso!!!" 1
	AddOutput "====================================================================================" 1
	exit 0
	
	fi
