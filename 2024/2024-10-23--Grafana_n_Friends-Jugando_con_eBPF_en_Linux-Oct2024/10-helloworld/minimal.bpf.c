/* SPDX-License-Identifier: (LGPL-2.1 OR BSD-2-Clause) */
//
#define BPF_NO_GLOBAL_DATA
#include <linux/bpf.h>
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_tracing.h>

typedef unsigned int u32;
typedef int pid_t;
const pid_t pid_filter = 0;

char LICENSE[] SEC("license") = "Dual BSD/GPL";

SEC("tp/syscalls/sys_enter_openat")
int minimal_bpf_handle_tp(void *ctx)
{
  pid_t pid = bpf_get_current_pid_tgid() >> 32;

  bpf_printk("BPF triggered sys_enter_openat from PID %d.\n", pid);
  return 0;
}