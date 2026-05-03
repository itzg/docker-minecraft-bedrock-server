/*
 * LD_PRELOAD shim for Minecraft Bedrock Dedicated Server (BDS).
 *
 * PURPOSE
 * -------
 * Allows SERVER_PORT and SERVER_PORT_V6 to be set to the same port number so
 * that both IPv4 and IPv6 clients can reach the server on a single port.
 *
 * USER-VISIBLE PROBLEM
 * --------------------
 * When a server is accessed via a hostname that resolves to both an IPv4 and
 * an IPv6 address, some players see "Unable to connect to world" while others
 * on the same network connect fine. The root cause is that BDS listens for
 * IPv4 and IPv6 on different ports by default (19132 and 19133). The Bedrock
 * client does not implement Happy Eyeballs (RFC 8305): it simply connects on
 * whichever address family its DNS lookup returns first, with no fallback.
 * Players whose devices resolve the hostname to IPv6 try port 19132 over IPv6,
 * find nothing listening there, and time out. Having both address families on
 * the same port eliminates the mismatch entirely.
 *
 * ROOT CAUSE IN BDS
 * -----------------
 * BDS opens its IPv6 UDP socket without ever calling setsockopt(IPV6_V6ONLY).
 * Confirmed via strace:
 *
 *   socket(AF_INET6, SOCK_DGRAM, IPPROTO_UDP) = 8
 *   bind(8, {sa_family=AF_INET6, sin6_port=htons(19133), "::"}, 28) = 0
 *
 * No setsockopt call appears between socket() and bind(). The socket therefore
 * inherits the host kernel default, controlled by net.ipv6.bindv6only. On
 * Linux the default is 0 (dual-stack), meaning the IPv6 socket bound to ::
 * also absorbs IPv4-mapped traffic (::ffff:x.x.x.x). When SERVER_PORT and
 * SERVER_PORT_V6 are set to the same value, BDS tries to bind a second socket
 * (AF_INET, 0.0.0.0) on an already-occupied port, gets EADDRINUSE, and — because
 * it does not handle this error — immediately segfaults. On the rare host where
 * bindv6only=1 the crash does not occur, but same-port configuration is still
 * not the default, so the mismatch problem persists.
 *
 * THE FIX
 * -------
 * This shim is loaded via LD_PRELOAD before BDS starts. It intercepts bind()
 * and, when it sees an AF_INET6 socket being bound to the BDS IPv6 port
 * (SERVER_PORT_V6 or the hardcoded default 19133), calls
 * setsockopt(IPV6_V6ONLY, 1) on that socket descriptor before passing the
 * bind() call through to the kernel. This makes the IPv6 socket strictly
 * IPv6-only, so the subsequent AF_INET bind on the same port number succeeds
 * without conflict. All other IPv6 sockets are left untouched.
 *
 * The shim is compiled at image build time (multi-stage, TCC) and adds no
 * compiler or build tooling to the final image.
 *
 * FAILURE MODES
 * -------------
 * - If the .so fails to load: the dynamic linker prints a warning and BDS
 *   starts normally with its original dual-stack behaviour.
 * - If setsockopt fails at runtime: a warning is logged and bind() is still
 *   called, so BDS starts with its original behaviour.
 * - If dlsym("bind") returns NULL (essentially impossible): the shim falls
 *   back to a raw syscall so BDS always gets a working bind().
 *
 * NOTE: the shim reads SERVER_PORT_V6 from the environment at startup. If the
 * IPv6 port is changed directly in server.properties (server-portv6) without
 * updating SERVER_PORT_V6, the shim watches the wrong port and IPV6_V6ONLY
 * will not be applied. Always use SERVER_PORT_V6 when this fix is enabled.
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
