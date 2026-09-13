# Set up the other Mac with Chezmoi and DeepSeek

Use these steps on the other workstation. Homebrew and Chezmoi are already installed. You do not need ChatGPT or `copilot-api`.

## 1. Apply the base dotfiles

If the dotfiles are already initialized, run:

```bash
chezmoi update --apply
```

Otherwise, run:

```bash
chezmoi init --apply 9710willy/dotfiles
```

Answer the setup prompts:

1. Select `company` or `personal` for the machine context.
2. Select `deepseek` for the Codex provider.
3. Enter the requested Git details if you selected `company`.

The first apply installs `gh`. It can stop before cloning the private development repositories.

## 2. Sign in to GitHub and finish the apply

```bash
gh auth status || gh auth login
chezmoi apply
```

Chezmoi installs the configured packages and runtimes. It also clones the development repositories and installs their commands, skills, hooks, and plugins.

## 3. Add your DeepSeek API key

Create a key at [DeepSeek API Keys](https://platform.deepseek.com/api-keys).

```bash
touch ~/.zshrc.local
chmod 600 ~/.zshrc.local
vi ~/.zshrc.local
```

Add this line with your real key:

```bash
export DEEPSEEK_API_KEY='your-key'
```

Save the file and start a new shell:

```bash
exec zsh
```

The key stays outside the dotfiles repository.

## 4. Test DeepSeek through Codex

```bash
codex exec -m deepseek-flash "Reply with OK."
```

Continue when the output contains `OK`.

## 5. Check the full setup

```bash
dotfiles-health
dev-sync status
codex plugin list --json
claude plugin list --json
```

The setup includes Codex, Claude Code, Imoten, Naru, Teio, Yeon, Evolve, Archify, Ripwire, and Ponytail.

## 6. Test Imoten

Start Codex:

```bash
codex
```

Enter this prompt:

```text
$imoten:unslop Rewrite this sentence: In order to proceed, we should utilize this configuration.
```

Do not run `$setup-pstack` on the DeepSeek workstation. That command still builds its model list from `copilot-api`. Direct Imoten workflows use `deepseek-flash`. Workflows that require several model vendors stop and report that limit.

## 7. Configure Teio before its first agent run

Chezmoi creates an empty `~/.config/teio/config.json`. This prevents Teio from writing its GPT-specific default preset on the DeepSeek workstation.

Add a project:

```bash
cd ~/work/your-project
teio project add your-project "$PWD"
```

Edit `~/.config/teio/config.json`. Add an execution preset that uses `deepseek-flash` with `high` effort before you run a coordinator or worker.

## 8. Sync active development

Commit your work before you move it between workstations.

On the workstation that has the new commits, run:

```bash
dev-sync push
```

On the other workstation, run these commands outside Codex:

```bash
dev-sync pull
dev-sync refresh
```

Restart Codex after `dev-sync refresh`.

Git syncs the development repositories. Chezmoi syncs the bootstrap and configuration. API keys, Naru databases, and Teio runtime state stay local.
