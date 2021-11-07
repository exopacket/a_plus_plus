/*
 * Copyright (c) 2000 Apple Computer, Inc. All rights reserved.
 * Portions Copyright (c) 2001 PADL Software Pty Ltd. All rights reserved.
 *
 * @APPLE_LICENSE_HEADER_START@
 *
 * Portions Copyright (c) 2000 Apple Computer, Inc.  All Rights
 * Reserved.  This file contains Original Code and/or Modifications of
 * Original Code as defined in and that are subject to the Apple Public
 * Source License Version 1.1 (the "License").  You may not use this file
 * except in compliance with the License.  Please obtain a copy of the
 * License at http://www.apple.com/publicsource and read it before using
 * this file.
 *
 * The Original Code and all software distributed under the License are
 * distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE OR NON- INFRINGEMENT.  Please see the
 * License for the specific language governing rights and limitations
 * under the License.
 *
 * @APPLE_LICENSE_HEADER_END@
 */

/******************************************************************
 * The purpose of this module is to provide a Touch ID
 * based authentication module for Mac OS X.
 ******************************************************************/

#include <CoreFoundation/CoreFoundation.h>

#define PAM_SM_AUTH
#define PAM_SM_ACCOUNT

#include <security/pam_modules.h>
#include <security/pam_appl.h>
#include <Security/Authorization.h>
#include <pwd.h>
PAM_EXTERN int
pam_sm_authenticate(pam_handle_t * pamh, int flags, int argc, const char **argv)
{

    const char *user = NULL;
    struct passwd *pwd = NULL;
    struct passwd pwdbuf;

    /* determine the required bufsize for getpwnam_r */
    int bufsize = sysconf(_SC_GETPW_R_SIZE_MAX);
    if (bufsize == -1) {
        bufsize = 2 * PATH_MAX;
    }

    /* get information about user to authenticate for */
    char *buffer = malloc(bufsize);
    if (pam_get_user(pamh, &user, NULL) != PAM_SUCCESS || !user ||
        getpwnam_r(user, &pwdbuf, buffer, bufsize, &pwd) != 0 || !pwd) {
        return PAM_AUTHINFO_UNAVAIL;
    }

    FILE *p;
    char ch;

    char command[101] = "";
    strcat(command, "/etc/PamUIHelperApp/PamUIHelper.app/Contents/MacOS/PamUIHelper");
    strcat(command, " -uname ");
    strcat(command, user);
    strcat(command, " 2>&1 ");

    p = popen(command,"r");

    if( p == NULL)
    {
        return PAM_AUTH_ERR;
    }

    while( (ch=fgetc(p)) != EOF) {

    }

    int status = pclose(p);

    int exitcode = WEXITSTATUS(status);

    if(exitcode == 21) {
        return PAM_SUCCESS;
    }

    return PAM_AUTH_ERR;

}


PAM_EXTERN int
pam_sm_setcred(pam_handle_t * pamh, int flags, int argc, const char **argv)
{
    return PAM_SUCCESS;
}


PAM_EXTERN int
pam_sm_acct_mgmt(pam_handle_t * pamh, int flags, int argc, const char **argv)
{
    return PAM_SUCCESS;
}
