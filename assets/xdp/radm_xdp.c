#include <linux/bpf.h>
#include <bpf/bpf_helpers.h>
#include <linux/if_ether.h>
#include <linux/ip.h>
#include <linux/tcp.h>
#include <linux/udp.h>

#define MAX_PPS 100000
#define SYN_FLOOD_THRESHOLD 1000

struct {
    __uint(type, BPF_MAP_TYPE_LRU_HASH);
    __uint(max_entries, 100000);
    __type(key, __u32);
    __type(value, __u64);
} packet_count SEC(".maps");

struct {
    __uint(type, BPF_MAP_TYPE_HASH);
    __uint(max_entries, 10000);
    __type(key, __u32);
    __type(value, __u64);
} blacklist SEC(".maps");

struct {
    __uint(type, BPF_MAP_TYPE_RINGBUF);
    __uint(max_entries, 1024 * 1024);
} events SEC(".maps");

struct event {
    __u32 src_ip;
    __u32 dst_ip;
    __u16 sport;
    __u16 dport;
    __u8 protocol;
    __u64 timestamp;
    __u32 drop_reason;
};

SEC("xdp")
int radm_filter(struct xdp_md *ctx) {
    void *data = (void *)(long)ctx->data;
    void *data_end = (void *)(long)ctx->data_end;
    struct ethhdr *eth = data;

    if ((void *)(eth + 1) > data_end) return XDP_PASS;
    if (eth->h_proto != __bpf_htons(ETH_P_IP)) return XDP_PASS;

    struct iphdr *ip = (void *)(eth + 1);
    if ((void *)(ip + 1) > data_end) return XDP_PASS;

    __u32 src_ip = ip->saddr;
    __u64 *count = bpf_map_lookup_elem(&packet_count, &src_ip);
    __u64 current = count ? *count + 1 : 1;
    bpf_map_update_elem(&packet_count, &src_ip, &current, BPF_ANY);

    if (current > MAX_PPS) {
        bpf_map_update_elem(&blacklist, &src_ip, &current, BPF_ANY);
        struct event *e = bpf_ringbuf_reserve(&events, sizeof(*e), 0);
        if (e) {
            e->src_ip = src_ip;
            e->timestamp = bpf_ktime_get_ns();
            e->drop_reason = 1;
            bpf_ringbuf_submit(e, 0);
        }
        return XDP_DROP;
    }

    if (ip->protocol == IPPROTO_TCP) {
        struct tcphdr *tcp = (void *)ip + (ip->ihl * 4);
        if ((void *)(tcp + 1) > data_end) return XDP_PASS;
        if (tcp->syn && !tcp->ack && current > SYN_FLOOD_THRESHOLD) {
            struct event *e = bpf_ringbuf_reserve(&events, sizeof(*e), 0);
            if (e) {
                e->src_ip = src_ip;
                e->timestamp = bpf_ktime_get_ns();
                e->drop_reason = 2;
                bpf_ringbuf_submit(e, 0);
            }
            return XDP_DROP;
        }
    }
    return XDP_PASS;
}
char _license[] SEC("license") = "GPL";