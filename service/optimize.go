package service

import (
	"bufio"
	"context"
	"fmt"
	"os"
	"os/exec"
	"runtime"
	"strings"
	"time"

	"github.com/alireza0/s-ui/logger"
)

type OptimizeService struct{}

// OptimizeResult represents the result of an optimization operation
type OptimizeResult struct {
	Success  bool     `json:"success"`
	Message  string   `json:"message"`
	Warnings []string `json:"warnings,omitempty"`
}

// SysctlInfo represents a single sysctl parameter value
type SysctlInfo struct {
	Key   string `json:"key"`
	Value string `json:"value"`
}

// SystemTuningStatus shows current state of system tuning
type SystemTuningStatus struct {
	BBREnabled    bool          `json:"bbr_enabled"`
	Optimized     bool          `json:"optimized"`
	ParamCount    int           `json:"param_count"`
	KernelVersion string        `json:"kernel_version"`
	CPUCount      int           `json:"cpu_count"`
	TotalMemMB    int64         `json:"total_mem_mb"`
	Params        []SysctlInfo  `json:"params,omitempty"`
}

// HealthCheckResult is the result of a comprehensive system health check
type HealthCheckResult struct {
	System struct {
		Hostname      string `json:"hostname"`
		OS            string `json:"os"`
		KernelVersion string `json:"kernel_version"`
		Uptime        string `json:"uptime"`
		CPUCount      int    `json:"cpu_count"`
		TotalMemMB    int64  `json:"total_mem_mb"`
		LoadAvg       string `json:"load_avg"`
	} `json:"system"`
	BBR        string `json:"bbr"`
	TCPParams  bool   `json:"tcp_params_ok"`
	DiskRoot   struct {
		Total string `json:"total"`
		Used  string `json:"used"`
		Avail string `json:"avail"`
		Pct   string `json:"pct"`
	} `json:"disk_root"`
	DNS struct {
		Reachable bool   `json:"reachable"`
		Latency   string `json:"latency"`
		Server    string `json:"server"`
	} `json:"dns"`
	Conntrack struct {
		Count    int    `json:"count"`
		Max      int    `json:"max"`
		UsagePct string `json:"usage_pct"`
	} `json:"conntrack"`
	Warnings []string `json:"warnings,omitempty"`
}

// runCmd executes a shell command and returns stdout + stderr
func (s *OptimizeService) runCmd(name string, args ...string) (string, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	cmd := exec.CommandContext(ctx, name, args...)
	out, err := cmd.CombinedOutput()
	return strings.TrimSpace(string(out)), err
}

// runBash executes a bash command string with a 30-second timeout
func (s *OptimizeService) runBash(script string) (string, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	cmd := exec.CommandContext(ctx, "bash", "-c", script)
	out, err := cmd.CombinedOutput()
	return strings.TrimSpace(string(out)), err
}

// GetTuningStatus returns the current system tuning status
func (s *OptimizeService) GetTuningStatus() *SystemTuningStatus {
	status := &SystemTuningStatus{}
	status.KernelVersion, _ = s.runCmd("uname", "-r")
	status.CPUCount = runtime.NumCPU()

	// Check BBR
	bbrOut, _ := s.runBash("sysctl net.ipv4.tcp_congestion_control 2>/dev/null | awk '{print $3}'")
	status.BBREnabled = strings.Contains(strings.ToLower(bbrOut), "bbr")

	// Check if tuning file exists
	info, err := os.Stat("/etc/sysctl.d/99-ygvpn-extreme.conf")
	if err == nil && info.Size() > 100 {
		status.Optimized = true
	}

	// Count optimized params from the file
	if status.Optimized {
		f, err := os.Open("/etc/sysctl.d/99-ygvpn-extreme.conf")
		if err == nil {
			defer f.Close()
			scanner := bufio.NewScanner(f)
			for scanner.Scan() {
				line := strings.TrimSpace(scanner.Text())
				if strings.Contains(line, "=") && !strings.HasPrefix(line, "#") {
					status.ParamCount++
				}
			}
		}
	}

	// Memory
	memKB, _ := s.runBash("grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}'")
	fmt.Sscanf(memKB, "%d", &status.TotalMemMB)
	status.TotalMemMB = status.TotalMemMB / 1024

	// Collect key params
	keyParams := []string{
		"net.ipv4.tcp_congestion_control",
		"net.ipv4.tcp_fastopen",
		"net.ipv4.tcp_mem",
		"net.ipv4.tcp_limit_output_bytes",
		"net.core.busy_poll",
		"net.core.busy_read",
		"vm.page-cluster",
		"vm.watermark_boost_factor",
		"vm.compaction_proactiveness",
		"kernel.timer_migration",
		"kernel.rcu_expedited",
	}
	for _, k := range keyParams {
		val, err := s.runBash(fmt.Sprintf("sysctl -n %s 2>/dev/null || echo 'N/A'", k))
		if err == nil {
			status.Params = append(status.Params, SysctlInfo{Key: k, Value: val})
		}
	}

	return status
}

// ApplyYGVPNTuning applies the YGVPN extreme network optimization to the system
func (s *OptimizeService) ApplyYGVPNTuning(opts map[string]bool) *OptimizeResult {
	result := &OptimizeResult{Success: true}

	if runtime.GOOS != "linux" {
		result.Success = false
		result.Message = "System optimization is only supported on Linux"
		return result
	}

	// Check root
	if os.Geteuid() != 0 {
		result.Success = false
		result.Message = "Root privileges required for system optimization"
		return result
	}

	aggressive := opts["aggressive"]
	busyPoll := opts["busy_poll"]
	noIPv6 := opts["no_ipv6"]
	unsafe := opts["unsafe"]

	// Step A: TCP/VM/Kernel core params
	sysctlFile := "/etc/sysctl.d/99-ygvpn-extreme.conf"
	s.stepLog("A", "TCP/VM/Kernel 核心参数")

	// Detect total memory for tcp_mem calculation
	memKB, _ := s.runBash("grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}'")
	var totalMemMB int64
	fmt.Sscanf(memKB, "%d", &totalMemMB)
	totalMemMB = totalMemMB / 1024

	var tcpMem, advWinScale string
	switch {
	case totalMemMB >= 16384:
		tcpMem = "131072 524288 2097152"
		advWinScale = "2"
	case totalMemMB >= 8192:
		tcpMem = "65536 262144 1048576"
		advWinScale = "2"
	case totalMemMB >= 4096:
		tcpMem = "32768 131072 524288"
		advWinScale = "1"
	default:
		tcpMem = "16384 65536 262144"
		advWinScale = "1"
	}

	tcpConf := fmt.Sprintf(`# YGVPN Extreme Network Optimization (applied by s-ui)
# Generated at system level — survives reboot

# ── TCP 内存压力阈值 ──
net.ipv4.tcp_mem = %s

# ── TCP 窗口激进调优 ──
net.ipv4.tcp_app_win = 0
net.ipv4.tcp_adv_win_scale = %s

# ── 连接指标隔离 ──
net.ipv4.tcp_no_metrics_save = 1

# ── 接收缓冲自动调谐 ──
net.ipv4.tcp_moderate_rcvbuf = 1

# ── 自动合并小包 ──
net.ipv4.tcp_autocorking = 1

# ── RFC1337 TIME_WAIT 保护 ──
net.ipv4.tcp_rfc1337 = 1

# ── 瘦流线性超时 ──
net.ipv4.tcp_thin_linear_timeouts = 1

# ── 重复 SACK ──
net.ipv4.tcp_dsack = 1

# ── 重传兼容模式关闭 ──
net.ipv4.tcp_retrans_collapse = 0

# ── TCP Small Queue (256KB, 抗 bufferbloat) ──
net.ipv4.tcp_limit_output_bytes = 262144

# ── Challenge ACK 不限制 ──
net.ipv4.tcp_challenge_ack_limit = 2147483647

# ── TFO 黑洞检测关闭 ──
net.ipv4.tcp_fastopen_blackhole_timeout_sec = 0

# ── 孤儿套接字回收加速 ──
net.ipv4.tcp_orphan_retries = 0

# ── 更激进断开死连接 ──
net.ipv4.tcp_retries2 = 8

# ── SYN 连接失败检测加速 ──
net.ipv4.tcp_syn_linear_timeouts = 2

# ── 窗口缩放允许 ──
net.ipv4.tcp_window_scaling = 1

# ── SACK 压缩微调 ──
net.ipv4.tcp_comp_sack_nr = 3
net.ipv4.tcp_comp_sack_slack_ns = 5000
net.ipv4.tcp_comp_sack_rtt_percent = 10

# ── UDP 最小缓冲区 ──
net.ipv4.udp_rmem_min = 16384
net.ipv4.udp_wmem_min = 16384

# ── ARP 调优 ──
net.ipv4.conf.all.arp_ignore = 1
net.ipv4.conf.default.arp_ignore = 1
net.ipv4.conf.all.arp_announce = 2
net.ipv4.conf.default.arp_announce = 2
net.ipv4.conf.all.arp_notify = 1
net.ipv4.conf.default.arp_notify = 1

# ── 不记录火星包日志 ──
net.ipv4.conf.all.log_martians = 0
net.ipv4.conf.default.log_martians = 0

# ── VM 极限调优 ──
vm.page-cluster = 0
vm.watermark_boost_factor = 0
vm.watermark_scale_factor = 50
vm.compaction_proactiveness = 0

# ── Kernel 调度 ──
kernel.timer_migration = 0
kernel.rcu_expedited = 1

# ── 辅助缓冲区 ──
net.core.optmem_max = 204800
`, tcpMem, advWinScale)

	err := os.WriteFile(sysctlFile, []byte(tcpConf), 0644)
	if err != nil {
		result.Success = false
		result.Message = fmt.Sprintf("Failed to write sysctl config: %v", err)
		return result
	}

	_, err = s.runCmd("sysctl", "-p", sysctlFile)
	if err != nil {
		result.Warnings = append(result.Warnings, fmt.Sprintf("sysctl apply had errors: %v", err))
	}
	result.Message = "TCP/VM/Kernel 参数已应用"

	// Step B: Busy Polling
	if busyPoll {
		s.stepLog("B", "Busy Polling")
		busyConf := "\n# ── Busy Polling (CPU 换低延迟) ──\nnet.core.busy_poll = 50\nnet.core.busy_read = 50\n"
		f, err := os.OpenFile(sysctlFile, os.O_APPEND|os.O_WRONLY, 0644)
		if err == nil {
			f.WriteString(busyConf)
			f.Close()
		}
		s.runCmd("sysctl", "-w", "net.core.busy_poll=50")
		s.runCmd("sysctl", "-w", "net.core.busy_read=50")
		result.Message += " | Busy Polling 已启用"
	}

	// Step C: Aggressive TCP
	if aggressive {
		s.stepLog("C", "激进 TCP 优化")
		aggrConf := "\n# ── 激进: 最小 RTO 50ms ──\nnet.ipv4.tcp_rto_min_us = 50000\n# ── 激进: SACK 延迟 ──\nnet.ipv4.tcp_comp_sack_delay_ns = 50000\n# ── 激进: 松散 rp_filter ──\nnet.ipv4.conf.all.rp_filter = 2\nnet.ipv4.conf.default.rp_filter = 2\n"
		f, err := os.OpenFile(sysctlFile, os.O_APPEND|os.O_WRONLY, 0644)
		if err == nil {
			f.WriteString(aggrConf)
			f.Close()
		}
		s.runCmd("sysctl", "-w", "net.ipv4.tcp_rto_min_us=50000")
		s.runCmd("sysctl", "-w", "net.ipv4.tcp_comp_sack_delay_ns=50000")
		s.runCmd("sysctl", "-w", "net.ipv4.conf.all.rp_filter=2")
		result.Warnings = append(result.Warnings, "激进模式: RTO 降至 50ms (可能影响高延迟链路)")
	}

	// Step D: Unsafe
	if unsafe {
		s.stepLog("D", "⚠ 高风险参数")
		unsafeConf := "\n# ── ⚠ 高风险: 关闭 SYN cookies ──\nnet.ipv4.tcp_syncookies = 0\n# ── ⚠ 高风险: 禁用 TCP 时间戳 ──\nnet.ipv4.tcp_timestamps = 0\n# ── ⚠ 高风险: RT 进程不限 CPU ──\nkernel.sched_rt_runtime_us = -1\n"
		f, err := os.OpenFile(sysctlFile, os.O_APPEND|os.O_WRONLY, 0644)
		if err == nil {
			f.WriteString(unsafeConf)
			f.Close()
		}
		s.runCmd("sysctl", "-w", "net.ipv4.tcp_syncookies=0")
		s.runCmd("sysctl", "-w", "net.ipv4.tcp_timestamps=0")
		s.runCmd("sysctl", "-w", "kernel.sched_rt_runtime_us=-1")
		result.Warnings = append(result.Warnings, "⚠ 高风险: SYN Cookies 关闭 (失去 SYN Flood 保护)")
	}

	// Step E: IPv6 disable
	if noIPv6 {
		s.stepLog("E", "禁用 IPv6")
		ipv6File := "/etc/sysctl.d/99-s-ui-disable-ipv6.conf"
		ipv6Conf := "# s-ui: 禁用 IPv6\nnet.ipv6.conf.all.disable_ipv6 = 1\nnet.ipv6.conf.default.disable_ipv6 = 1\n"
		if _, err := os.Stat(ipv6File); os.IsNotExist(err) {
			os.WriteFile(ipv6File, []byte(ipv6Conf), 0644)
			s.runCmd("sysctl", "-p", ipv6File)
			result.Message += " | IPv6 已禁用"
		}
	}

	// Step F: Conntrack UDP timeout
	s.stepLog("F", "Conntrack UDP 精调")
	conntrackConf := "\n# ── UDP conntrack 激进回收 (Hysteria2/Tuic5) ──\nnet.netfilter.nf_conntrack_udp_timeout = 20\nnet.netfilter.nf_conntrack_udp_timeout_stream = 60\n"
	f, err := os.OpenFile(sysctlFile, os.O_APPEND|os.O_WRONLY, 0644)
	if err == nil {
		f.WriteString(conntrackConf)
		f.Close()
	}
	s.runCmd("sysctl", "-w", "net.netfilter.nf_conntrack_udp_timeout=20")
	s.runCmd("sysctl", "-w", "net.netfilter.nf_conntrack_udp_timeout_stream=60")

	// Step G: Ethtool optimization
	s.stepLog("G", "网卡 Ethtool 优化")
	ethtoolOut, _ := s.runBash(`
		if command -v ethtool &>/dev/null; then
			for eth in $(ls /sys/class/net 2>/dev/null | grep -vE "lo|docker|veth|br-|tun|sit0|wg"); do
				ethtool -C "$eth" adaptive-rx off 2>/dev/null || true
				ethtool -C "$eth" adaptive-tx off 2>/dev/null || true
				ethtool -K "$eth" sg on 2>/dev/null || true
				ethtool -K "$eth" tx-udp-segmentation on 2>/dev/null || true
				ethtool -K "$eth" ntuple on 2>/dev/null || true
				ethtool -A "$eth" autoneg on rx off tx off 2>/dev/null || true
			done
			echo "ethtool done"
		else
			echo "ethtool not available"
		fi
	`)
	if strings.Contains(ethtoolOut, "not available") {
		result.Warnings = append(result.Warnings, "ethtool 不可用，跳过网卡优化")
	} else {
		// XPS (Transmit Packet Steering)
		s.runBash(fmt.Sprintf(`
			CPUS=$(nproc)
			XPS=$(printf "%%x" $(((1 << CPUS) - 1)))
			for eth in $(ls /sys/class/net 2>/dev/null | grep -vE "lo|docker|veth|br-|tun|sit0|wg"); do
				for xps_file in /sys/class/net/$eth/queues/tx-*/xps_cpus; do
					[ -f "$xps_file" ] && echo "$XPS" > "$xps_file" 2>/dev/null || true
				done
			done
		`, runtime.NumCPU()))
	}

	// Step H: Sing-box RT priority
	s.stepLog("H", "Sing-box 进程优化")
	s.runBash(`
		if pgrep -x sing-box > /dev/null 2>&1; then
			SB_PID=$(pgrep -x sing-box | head -1)
			chrt -f -p 99 "$SB_PID" 2>/dev/null || true
		fi
	`)

	// Apply sing-box LimitMEMLOCK in systemd unit
	s.runBash(`
		if [ -f /etc/systemd/system/sing-box.service ]; then
			if ! grep -q "LimitMEMLOCK=" /etc/systemd/system/sing-box.service; then
				sed -i '/^\[Service\]/a LimitMEMLOCK=infinity' /etc/systemd/system/sing-box.service
				systemctl daemon-reload 2>/dev/null || true
			fi
		fi
	`)

	logger.Info("YGVPN extreme optimization applied successfully")
	return result
}

// ToggleBBR enables or disables BBR congestion control
func (s *OptimizeService) ToggleBBR(enable bool) *OptimizeResult {
	result := &OptimizeResult{Success: true}

	if runtime.GOOS != "linux" {
		result.Success = false
		result.Message = "BBR is only available on Linux"
		return result
	}
	if os.Geteuid() != 0 {
		result.Success = false
		result.Message = "Root privileges required to toggle BBR"
		return result
	}

	bbrConf := "/etc/sysctl.d/99-ygvpn-extreme.conf"
	if enable {
		// Check kernel support
		avail, _ := s.runBash("sysctl net.ipv4.tcp_available_congestion_control 2>/dev/null")
		if strings.Contains(avail, "bbr") {
			s.runCmd("sysctl", "-w", "net.ipv4.tcp_congestion_control=bbr")
			s.runCmd("sysctl", "-w", "net.core.default_qdisc=fq")
			// Make persistent in the same file as YGVPN tuning
			s.runBash(fmt.Sprintf(`grep -q "tcp_congestion_control" %s 2>/dev/null && \
				sed -i 's/net.ipv4.tcp_congestion_control.*/net.ipv4.tcp_congestion_control = bbr/' %s || \
				echo "net.ipv4.tcp_congestion_control = bbr" >> %s
			grep -q "default_qdisc" %s 2>/dev/null && \
				sed -i 's/net.core.default_qdisc.*/net.core.default_qdisc = fq/' %s || \
				echo "net.core.default_qdisc = fq" >> %s`, bbrConf, bbrConf, bbrConf, bbrConf, bbrConf, bbrConf))
			result.Message = "BBR + fq qdisc enabled"
		} else {
			result.Success = false
			result.Message = "BBR not available (kernel >= 4.9 required)"
		}
	} else {
		s.runCmd("sysctl", "-w", "net.ipv4.tcp_congestion_control=cubic")
		s.runCmd("sysctl", "-w", "net.core.default_qdisc=pfifo_fast")
		result.Message = "BBR disabled, fallback to CUBIC + pfifo_fast"
	}

	return result
}

// HealthCheck runs a comprehensive system health check
func (s *OptimizeService) HealthCheck() *HealthCheckResult {
	r := &HealthCheckResult{}

	// System info
	r.System.Hostname, _ = os.Hostname()
	r.System.OS = runtime.GOOS
	r.System.KernelVersion, _ = s.runCmd("uname", "-r")
	r.System.CPUCount = runtime.NumCPU()
	r.System.LoadAvg, _ = s.runBash("cat /proc/loadavg 2>/dev/null | awk '{print $1, $2, $3}' || echo 'N/A'")

	memKB, _ := s.runBash("grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}'")
	fmt.Sscanf(memKB, "%d", &r.System.TotalMemMB)
	r.System.TotalMemMB = r.System.TotalMemMB / 1024

	r.System.Uptime, _ = s.runBash("uptime -p 2>/dev/null || echo 'N/A'")

	// BBR status
	r.BBR, _ = s.runBash("sysctl net.ipv4.tcp_congestion_control 2>/dev/null | awk '{print $3}' || echo 'N/A'")

	// TCP params check
	tcpParams := []string{
		"net.ipv4.tcp_fastopen",
		"net.ipv4.tcp_sack",
		"net.ipv4.tcp_window_scaling",
	}
	allOK := true
	for _, p := range tcpParams {
		val, _ := s.runBash(fmt.Sprintf("sysctl -n %s 2>/dev/null || echo '0'", p))
		if val == "0" || val == "" {
			allOK = false
			r.Warnings = append(r.Warnings, fmt.Sprintf("%s 未启用", p))
		}
	}
	r.TCPParams = allOK

	// Disk
	r.DiskRoot.Total, _ = s.runBash("df -h / 2>/dev/null | tail -1 | awk '{print $2}' || echo 'N/A'")
	r.DiskRoot.Used, _ = s.runBash("df -h / 2>/dev/null | tail -1 | awk '{print $3}' || echo 'N/A'")
	r.DiskRoot.Avail, _ = s.runBash("df -h / 2>/dev/null | tail -1 | awk '{print $4}' || echo 'N/A'")
	r.DiskRoot.Pct, _ = s.runBash("df -h / 2>/dev/null | tail -1 | awk '{print $5}' || echo 'N/A'")

	// DNS
	dnsOut, dnsName := "", "223.5.5.5"
	dnsOut, _ = s.runBash("timeout 3 ping -c 1 -W 2 223.5.5.5 2>&1 | grep -oP 'time=\\K[0-9.]+'")
	if dnsOut == "" {
		dnsOut, _ = s.runBash("timeout 3 ping -c 1 -W 2 1.1.1.1 2>&1 | grep -oP 'time=\\K[0-9.]+'")
		dnsName = "1.1.1.1"
	}
	if dnsOut == "" {
		dnsOut, _ = s.runBash("timeout 3 ping -c 1 -W 2 8.8.8.8 2>&1 | grep -oP 'time=\\K[0-9.]+'")
		dnsName = "8.8.8.8"
	}
	if dnsOut != "" {
		r.DNS.Reachable = true
		r.DNS.Latency = dnsOut + "ms"
		r.DNS.Server = dnsName
	} else {
		r.DNS.Reachable = false
		r.DNS.Latency = "timeout"
		r.Warnings = append(r.Warnings, "DNS unreachable (223.5.5.5, 1.1.1.1, 8.8.8.8)")
	}

	// Conntrack
	r.Conntrack.Count, _ = func() (int, error) {
		var n int
		out, _ := s.runBash("cat /proc/sys/net/netfilter/nf_conntrack_count 2>/dev/null || echo '0'")
		_, err := fmt.Sscanf(out, "%d", &n)
		return n, err
	}()
	r.Conntrack.Max, _ = func() (int, error) {
		var n int
		out, _ := s.runBash("cat /proc/sys/net/netfilter/nf_conntrack_max 2>/dev/null || echo '262144'")
		_, err := fmt.Sscanf(out, "%d", &n)
		return n, err
	}()
	if r.Conntrack.Max > 0 {
		pct := float64(r.Conntrack.Count) / float64(r.Conntrack.Max) * 100
		r.Conntrack.UsagePct = fmt.Sprintf("%.1f%%", pct)
		if pct > 90 {
			r.Warnings = append(r.Warnings, fmt.Sprintf("Conntrack 使用率 %.1f%%，接近上限", pct))
		}
	}

	return r
}

func (s *OptimizeService) stepLog(step string, name string) {
	logger.Infof("[优化] Step %s: %s", step, name)
}
