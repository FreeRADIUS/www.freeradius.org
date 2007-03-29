MAN	= ../../../branch_1_1/man
FILES	= radclient radeapclient radiusd radlast radrelay radsqlrelay \
	radtest radwatch radwho radzap rlm_acct_unique rlm_always \
	rlm_attr_filter rlm_attr_rewrite rlm_chap rlm_counter rlm_detail \
	rlm_expr rlm_files rlm_mschap rlm_pap rlm_passwd rlm_realm \
	rlm_sql_log rlm_sql rlm_unix

all:
	for x in $(FILES); \
	do \
		src=`echo $(MAN)/*/$$x\.[0-9]`; \
		nroff -man -Tascii $$src | col -b > $$x.txt; \
	done
