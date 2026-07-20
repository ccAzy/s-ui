package config

// SplitDomainPreset is a named group of domains for WARP/IPv6 split routing
type SplitDomainPreset struct {
	Name        string   `json:"name"`
	Description string   `json:"description"`
	Domains     []string `json:"domains"`
}

// SplitDomainPresets returns the built-in domain split presets
// based on YGVPN's curated list of 30+ common sites
func SplitDomainPresets() []SplitDomainPreset {
	return []SplitDomainPreset{
		{
			Name:        "ai-sites",
			Description: "AI/Chat 类站点 (ChatGPT, Claude, Gemini, Perplexity, OpenAI)",
			Domains: []string{
				"chatgpt.com",
				"openai.com",
				"claude.ai",
				"gemini.google.com",
				"perplexity.ai",
				"copilot.microsoft.com",
				"bard.google.com",
			},
		},
		{
			Name:        "streaming",
			Description: "流媒体 (Netflix, Disney+, YouTube, Spotify, Hulu, Twitch)",
			Domains: []string{
				"netflix.com",
				"disneyplus.com",
				"hulu.com",
				"hbomax.com",
				"spotify.com",
				"youtube.com",
				"twitch.tv",
			},
		},
		{
			Name:        "social",
			Description: "社交平台 (Twitter/X, Facebook, Instagram, Reddit, Discord, Telegram)",
			Domains: []string{
				"twitter.com",
				"x.com",
				"facebook.com",
				"instagram.com",
				"reddit.com",
				"discord.com",
				"t.me",
				"telegram.org",
			},
		},
		{
			Name:        "developer",
			Description: "开发者站点 (GitHub, GitLab, Stack Overflow, Docker, NPM, Medium, Wikipedia)",
			Domains: []string{
				"github.com",
				"gitlab.com",
				"stackoverflow.com",
				"docker.com",
				"npmjs.com",
				"medium.com",
				"wikipedia.org",
				"quora.com",
				"patreon.com",
			},
		},
		{
			Name:        "google-services",
			Description: "Google 服务 (搜索, Gmail, 地图, API, Blogger, 广告)",
			Domains: []string{
				"google.com",
				"gmail.com",
				"googleapis.com",
				"blogspot.com",
				"googleusercontent.com",
				"ggpht.com",
				"googleadservices.com",
			},
		},
		{
			Name:        "microsoft",
			Description: "Microsoft 服务 (Bing, Office 365, Azure, Microsoft)",
			Domains: []string{
				"microsoft.com",
				"bing.com",
				"office.com",
				"office365.com",
				"azure.com",
				"live.com",
				"outlook.com",
			},
		},
	}
}
