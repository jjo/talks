#include <vmlinux.h>
#include <bpf/bpf_endian.h>
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_tracing.h>

// Stolen from <linux/pkt_cls.h>
#define TC_ACT_OK 0
#define TC_ACT_SHOT 2

#define ETH_P_IP 0x0800 /* Internet Protocol packet */

/// @tchook {"ifindex":1, "attach_point":"BPF_TC_EGRESS"}
/// @tcopts {"handle":1, "priority":1}
SEC("tc")
int tc_bpf_egress(struct __sk_buff *ctx)
{
  void *data_end = (void *)(__u64)ctx->data_end;
  void *data = (void *)(__u64)ctx->data;
  struct ethhdr *l2;
  struct iphdr *l3;

  if (ctx->protocol != bpf_htons(ETH_P_IP))
    return TC_ACT_OK;

  l2 = data;
  if ((void *)(l2 + 1) > data_end)
    return TC_ACT_OK;

  l3 = (struct iphdr *)(l2 + 1);
  if ((void *)(l3 + 1) > data_end)
    return TC_ACT_OK;

  int action = TC_ACT_OK;
  //int action = TC_ACT_SHOT;
  bpf_printk("Got IP packet: tot_len: %d, ttl: %d, dst: %08x, action: %d",
	     bpf_ntohs(l3->tot_len), l3->ttl, bpf_ntohl(l3->daddr), action);
  return action;
}

char __license[] SEC("license") = "GPL";
