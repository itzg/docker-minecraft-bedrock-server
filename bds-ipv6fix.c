/*
 * LD_PRELOAD shim for Minecraft Bedrock Dedicated Server.
 *
 * BDS never sets IPV6_V6ONLY on its IPv6 UDP socket, leaving it in dual-stack
 * mode. This prevents binding IPv4 and IPv6 to the same port number because
 * the wildcard IPv6 socket absorbs IPv4-mapped traffic, causing EADDRINUSE
 * and a hard segfault in BDS.
 *
 * The purpose of this shim is to allow SERVER_PORT and SERVER_PORT_V6 to be
 * set to the same port number. This is beneficial for servers accessed via
 * hostnames that resolve to both IPv4 and IPv6 addresses, because the Bedrock
 * client does not implement Happy Eyeballs (RFC 8305): it connects on
 * whichever address family the DNS response arrives first, which may differ
 * between clients. Having both address families listen on the same port
 * eliminates the mismatch, since clients can reach the server regardless of
 * which address family their DNS lookup returns.
 *
 * Without this shim, BDS never sets IPV6_V6ONLY explicitly, so the socket
 * inherits the host kernel default (net.ipv6.bindv6only). The Linux default
 * is dual-stack (IPV6_V6ONLY=0), which is therefore the common case: same-port
 * configuration causes EADDRINUSE and a hard segfault. On the rare host with
 * bindv6only=1 the crash does not occur, but this shim ensures consistent
 * behaviour regardless of host configuration. This shim intercepts bind() and sets
 * IPV6_V6ONLY=1 only for the BDS IPv6 port (default 19133 or SERVER_PORT_V6),
 * leaving all other IPv6 sockets untouched.
 *
 * Enabled via ENABLE_BDS_V6BIND_FIX=true in bedrock-entry.sh.
 *
 * NOTE: the shim reads SERVER_PORT_V6 from the environment at startup. If the
 * IPv6 port is changed directly in server.properties (server-portv6) without
 * setting SERVER_PORT_V6 accordingly, the shim will watch the wrong port and
 * IPV6_V6ONLY will not be applied. Always use SERVER_PORT_V6 to configure the
 * IPv6 port when this fix is enabled.
 */
#define _GNU_SOURCE
#include <dlfcn.h>
#include <netinet/in.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/socket.h>
#include <sys/syscall.h>
#include <unistd.h>

#define BDS_DEFAULT_PORT_V6 19133

static int (*real_bind)(int, const struct sockaddr *, socklen_t)       = NULL;
static int (*real_setsockopt)(int, int, int, const void *, socklen_t)  = NULL;

static int target_port = BDS_DEFAULT_PORT_V6;

__attribute__((constructor))
static void bds_ipv6fix_init(void) {
    real_bind       = dlsym(RTLD_NEXT, "bind");
    real_setsockopt = dlsym(RTLD_NEXT, "setsockopt");

    const char *pv6 = getenv("SERVER_PORT_V6");
    if (pv6) target_port = atoi(pv6);

    fprintf(stderr, "[bds-ipv6fix] active, SERVER_PORT_V6=%d (default=%d)\n",
            target_port, BDS_DEFAULT_PORT_V6);
}

int bind(int fd, const struct sockaddr *addr, socklen_t len) {
    if (addr->sa_family == AF_INET6) {
        int port = (int)ntohs(((const struct sockaddr_in6 *)addr)->sin6_port);
        if (real_setsockopt && (port == BDS_DEFAULT_PORT_V6 || port == target_port)) {
            int one = 1;
            int rc = real_setsockopt(fd, IPPROTO_IPV6, IPV6_V6ONLY, &one, sizeof(one));
            if (rc == 0)
                fprintf(stderr, "[bds-ipv6fix] IPV6_V6ONLY=1 set on fd=%d port=%d\n", fd, port);
            else
                fprintf(stderr, "[bds-ipv6fix] WARNING: failed to set IPV6_V6ONLY on fd=%d port=%d\n", fd, port);
        }
    }
    if (real_bind)
        return real_bind(fd, addr, len);
    return (int)syscall(SYS_bind, fd, addr, len);
}
