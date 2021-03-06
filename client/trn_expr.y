%token INTEGER NREF PREF FIRST LAST NEXT PREV FREF LREF CUR NEW ALL AREF
%left '+' '-'
%{
#include <ctype.h>
#include <discuss/discuss.h>
#include "globals.h"

static trn_info *trnexpr_curtrn;
static mtg_info *trnexpr_curmtg;
static int trnexpr_low, trnexpr_high;
static int trnexpr_aref;
static char *cp;
static int trnexpr_err;
%}

%%
range	: trn_no 
		{ trnexpr_low = $1;
		  trnexpr_high = $1;
		}
	| trn_no sep trn_no
		{ trnexpr_low = $1;
		  trnexpr_high = $3;
		}
	| NEW
		{ trnexpr_low = dsc_public.highest_seen+1;
		  trnexpr_high = trnexpr_curmtg->last;
	        }
	| ALL
	        { trnexpr_low = trnexpr_curmtg->first;
		  trnexpr_high = trnexpr_curmtg->last;
		}
	| AREF
	        { trnexpr_low = trnexpr_curtrn->current;
		  trnexpr_high = trnexpr_curtrn->current;
		  trnexpr_aref = 1;
		}

	;	  
sep	: ':'
	| ','
	;

trn_no	: INTEGER
	| NREF
	| PREF
	| FIRST
	| LAST
	| NEXT
	| PREV
	| FREF
	| LREF
	| CUR
	| expr
	;

expr	: trn_no '-' trn_no
		{ $$ = $1 - $3; }
	| trn_no '+' trn_no
		{ $$ = $1 + $3; }
	;
%%

/*
 *
 *	Copyright (C) 1989 by the Massachusetts Institute of Technology
 *    	Developed by the MIT Student Information Processing Board (SIPB).
 *    	For copying information, see the file mit-copyright.h in this release.
 *
 */

yyerror(msg)
	char *msg;
{
#ifdef	lint
	msg = msg;
#endif	/* lint */
	trnexpr_err = DISC_INVALID_TRN_SPECS;
}

/*
 *
 * see if second string is beginning of first string, except for case
 * differences..
 *
 */

#define	to_lower(c)	(((c)<'_')?((c)+'a'-'A'):(c))
static match(s1, s2)
	register char *s1, *s2;
{
	while (*s2) {
		if (to_lower(*s1) != *s2)
			return(0);
		s1++; s2++;
	}
	return(1);
}

yylex()
{
	if (!*cp) return -1;
	if(isdigit(*cp)) {
		yylval=0;
		do {
			yylval = *(cp++) - '0' + yylval*10;
		} while (*cp && isdigit(*cp));
		return( INTEGER );
	} else if (*cp=='.') {
		cp++;
		yylval=trnexpr_curtrn->current;
		return(CUR);
	} else if (*cp==':' || *cp=='+' || *cp=='-') {
		return(*cp++);
	} else if (match(cp, "current")) {
	        cp += 7;
	        yylval=trnexpr_curtrn->current;
		return(CUR);
	} else if (match(cp, "new")) {
	        cp += 3;
		return(NEW);
	} else if (match(cp, "all")) {
	        cp += 3;
		return(ALL);
	} else if (match(cp, "aref")) {
		cp += 4;
		return(AREF);
	} else if (match(cp, "next")) {
		cp += 4;
		yylval=trnexpr_curtrn->next;
		return(NEXT);
	} else if (match(cp, "prev")) {
		cp += 4;
		yylval=trnexpr_curtrn->prev;
		return(PREV);
	} else if (match(cp, "back")) {
		cp += 4;
		yylval=trnexpr_curtrn->prev;
		return(PREV);
 	} else if (match(cp, "nref")) {
		cp += 4;
		yylval=trnexpr_curtrn->nref;
		return(NREF);
	} else if (match(cp, "pref")) {
		cp += 4;
		yylval=trnexpr_curtrn->pref;
		return(PREF);
 	} else if (match(cp, "first")) {
		cp += 5;
		yylval=trnexpr_curmtg->first;
		return(FIRST);
	} else if (match(cp, "last")) {
		cp += 4;
		yylval=trnexpr_curmtg->last;
		return(LAST);
	} else if (match(cp, "fref")) {
		cp += 4;
		yylval=trnexpr_curtrn->fref;
		return(FREF);
	} else if (match(cp, "lref")) {
		cp += 4;
		yylval=trnexpr_curtrn->lref;
		return(LREF);
	} else if (match(cp, "n")) {
		cp += 1;
		yylval=trnexpr_curtrn->next;
		return(NEXT);
	} else if (match(cp, "b") || match(cp, "p")) {
		cp += 1;
		yylval=trnexpr_curtrn->prev;
		return(PREV);
  	} else if (*cp=='l' || *cp=='L') {
		cp++;
		yylval=trnexpr_curmtg->last;
		return(LAST);
 	} else if (*cp=='f' || *cp == 'F') {
		cp++;
		yylval=trnexpr_curmtg->first;
		return(FIRST);
	} else return (*cp++);
}

int trnexpr_parse(mtg, trn, string, lorange, highrange, flags) 
        mtg_info *mtg;
  	trn_info *trn;
	char *string;
	int *lorange, *highrange, *flags;
{
	cp = string;
	trnexpr_curmtg = mtg;
	trnexpr_curtrn = trn;
	trnexpr_aref = 0;
	trnexpr_err = 0;
	(void) yyparse();
	if(lorange)
		*lorange = trnexpr_low;
	if(highrange)
		*highrange = trnexpr_high;
	if(flags)
		*flags = (trnexpr_aref) ? flag_AREF : 0;
	return(trnexpr_err);
}

#ifdef notdef
mtg_info mtg = { 0, "/tmp/foo", "bar", "quux", 1, 30, 22, 23, 1 };
trn_info trn = { 0, 7, 6, 8, 5, 9, 2, 17, 3, 42, 7, 48, "Qux", "me" };
main(argc, argv) 
	int argc;
	char **argv;
{
	int low, high;
	argv++; argc--;
	while(argc--) {
		low = -1; high = -1;
		trnexpr_parse(&mtg, &trn, *argv, &low, &high);
		printf("%s: %d:%d\n", *argv, low, high);
		if(trnexpr_err) {
			printf("Error %d\n", trnexpr_err);
			trnexpr_err=0;
		}
		argv++;
	}
}
#endif /* notdef */
