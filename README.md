# Orgchart

Interactive organization chart generator built with Elixir and Phoenix LiveView.

## Features

- Upload CSV files with org data (auto-detects comma or semicolon delimiter)
- Hierarchical tree visualization with connecting lines
- Children grouped by role, then by team
- Organization statistics (total size, by role, by team)

## CSV Format

```csv
name;role;team;lead
Sarah Johnson;CEO;Executive;
Michael Chen;VP Engineering;Engineering;Sarah Johnson
```

- `lead` column contains the name of the person's manager
- Empty `lead` = root node

## Setup with Devbox

1. Install [Devbox](https://www.jetify.com/devbox)

2. Enter the devbox shell:
   ```bash
   devbox shell
   ```
   This automatically runs `mix deps.get` on entry.

3. Start the server:
   ```bash
   mix phx.server
   ```

4. Visit [localhost:4000](http://localhost:4000)

## Devbox Scripts

```bash
devbox run test   # Run tests
devbox run dev    # Clean rebuild and start server
```
