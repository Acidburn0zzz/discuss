/*
 *
 *	Copyright (C) 1988, 1989 by the Massachusetts Institute of Technology
 *    	Developed by the MIT Student Information Processing Board (SIPB).
 *    	For copying information, see the file mit-copyright.h in this release.
 *
 */
/*
 *
 * disserve.c -- Simple top level program for test.
 *
 * $Header: /afs/dev.mit.edu/source/repository/athena/bin/discuss/server/disserve.c,v 1.4 1989-06-03 00:42:58 srz Exp $
 * $Log: not supported by cvs2svn $
 * Revision 1.3  89/06/01  16:26:56  srz
 * John Kohl's patch for Ultrix 3.0.
 * 
 * Revision 1.2  88/10/08  01:38:16  raeburn
 * Added some syslog code.
 * 
 */

#include <stdio.h>
#include <syslog.h>
extern char *error_message();

int main (argc,argv)
    int argc;
    char **argv;
{
    int code;

#ifndef SUBPROC
#ifdef LOG_DAEMON
    openlog ("discuss", LOG_PID, LOG_DAEMON);
#else
    openlog ("discuss", LOG_PID);
#endif
#endif
    init_rpc("discuss",&code);
    if (code) {
#ifndef SUBPROC
	syslog (LOG_ERR, "RPC initialization failed: %s",
		error_message (code));
#else
	fprintf(stderr, "%s\n", error_message(code));
#endif
	exit(1);
    }
    while (!code)
	recvit (&code);
    return 0;
}
