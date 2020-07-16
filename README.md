# action-notify

## Env variables

| name               | description                                     |
| ------------------ | ----------------------------------------------- |
| CUSTOM_SCRIPT      | Fully custom control, make your own run script. |
| TELEGRAM_BOT_TOKEN |                                                 |
| TELEGRAM_CHAT_ID   |                                                 |

- You can use this action built in variables, see above.
- or use [Github action variables](https://docs.github.com/en/actions/configuring-and-managing-workflows/using-environment-variables#default-environment-variables)
- or make custom variable by import from [GitHub context](https://docs.github.com/en/actions/reference/context-and-expression-syntax-for-github-actions#contexts)
- or make your own variable

## Examples

> Custom template example

This template will format by [envsubst](https://www.gnu.org/software/gettext/manual/html_node/envsubst-Invocation.html) program.

```txt
chat id: ${TELEGRAM_CHAT_ID}
repo owner: ${CUSTOM_VAR1}
custom var: ${CUSTOM_VAR2}
```

> Workflow example

```yml
on: [push]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - name: Notify telegram
      uses: up9cloud/action-notify@v1
      env:
        TELEGRAM_BOT_TOKEN: ${{secrets.TELEGRAM_BOT_TOKEN}}
        TELEGRAM_CHAT_ID: ${{secrets.TELEGRAM_CHAT_ID}}
        # Custom template file path relative to the repo root
        TEMPLATE_PATH: "./test/custom.txt"
        # Set a custom variable from github context
        CUSTOM_VAR1: ${{github.repository_owner}}
        # Set a custom variable
        CUSTOM_VAR2: "a custom variable"
```

See [more examples](https://github.com/up9cloud/action-notify/blob/master/.github/workflows/main.yml)

## TODO

- [x] Telegram
- [ ] Webhook
- [ ] Slack
- [ ] Discord
- [ ] Teams
- [ ] Gitter
- [ ] Line
- [ ] IRC
- [ ] Android push notifications
- [ ] IOS APNs
- [ ] Facebook
- [ ] Google Chat
