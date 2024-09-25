struct stat sb;
if (stat(path, &sb))
        perror("stat"), exit(111);
if (/* path is under /project/foo && sb.st_uid is in the foo group
       && sb.st_gid is the primary group of sb.st_uid */) \{
        if (chown(path, sb.st_uid, foo_gid))
                perror("chown"), exit(111);
\}
