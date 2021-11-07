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

char** str_split(char* a_str, const char a_delim)
{
    char** result    = 0;
    size_t count     = 0;
    char* tmp        = a_str;
    char* last_comma = 0;
    char delim[2];
    delim[0] = a_delim;
    delim[1] = 0;

    /* Count how many elements will be extracted. */
    while (*tmp)
    {
        if (a_delim == *tmp)
        {
            count++;
            last_comma = tmp;
        }
        tmp++;
    }

    /* Add space for trailing token. */
    count += last_comma < (a_str + strlen(a_str) - 1);

    /* Add space for terminating null string so caller
       knows where the list of returned strings ends. */
    count++;

    result = malloc(sizeof(char*) * count);

    if (result)
    {
        size_t idx  = 0;
        char* token = strtok(a_str, delim);

        while (token)
        {
            assert(idx < count);
            *(result + idx++) = strdup(token);
            token = strtok(0, delim);
        }
        assert(idx == count - 1);
        *(result + idx) = 0;
    }

    return result;
}

char* replace_char(char* str, char find, char replace){
    char *current_pos = strchr(str,find);
    while (current_pos) {
        *current_pos = replace;
        current_pos = strchr(current_pos,find);
    }
    return str;
}

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

    char command[148] = "";
    strcat(command, "/etc/PamUIHelperApp/PamUIHelper.app/Contents/MacOS/PamUIHelper");
    strcat(command, " -uname ");
    strcat(command, user);
    strcat(command, " -hwcheck yes ");
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

        FILE *ptr;
        ptr = popen("exec xcrun xctrace list devices","r");

        if( ptr == NULL)
        {
            return 2;
        }

        char *out = NULL;
        size_t outlen = 0;

        bool foundDevices = false;
        bool foundSims = false;

        while ((getline(&out, &outlen, ptr) >= 0) && !foundSims)
        {

            if(strcmp("== Simulators ==\n", out) == 0) {
                foundSims = true;
                break;
            }

            if(strcmp(out, "== Devices ==\n") == 0) {
                foundDevices = true;
                continue;
            }

            if(foundDevices == true) {

                char** tokens;
                tokens = str_split(out, '(');

                if (tokens)
                {
                    int i;
                    for (i = 0; *(tokens + i); i++)
                    {

                        char* str = *(tokens + i);
                        replace_char(str, '\n', '\0');
                        replace_char(str, ')', '\0');

                        //INSERT UUID BELOW
                        if(strcmp(str, "") == 0) {
                            return PAM_SUCCESS;
                        }

                        free(*(tokens + i));
                    }
                    free(tokens);
                }

            }

        }

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
