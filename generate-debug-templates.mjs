import fs from 'fs/promises'
import path from 'path'
import { fileURLToPath  } from 'url'

const templateDir = path.join(path.dirname(fileURLToPath(import.meta.url)), 'template')
const raw = await fs.readFile(path.join(templateDir, 'env.txt'), 'utf8')
let envs = []
for (const s of raw.split('\n')) {
  if (s.trim() === '' || s.trim().startsWith('#')) {
    continue
  }
  envs.push(s)
}
const expressions = envs.map(s => `${s}: \${${s}}`)
let jobs = []
jobs.push(
fs.writeFile(path.join(templateDir, 'discord', 'debug.json'), `{
  "tts": false,
  "embeds": [
    {
      "description": "\`\`\`${expressions.join('\\n')}\`\`\`"
    }
  ]
}`),
fs.writeFile(path.join(templateDir, 'line.me', 'debug.json'), `{
  "messages":[
    {
      "type":"text",
      "text":"${expressions.join('\\n')}"
    }
  ]
}`),
fs.writeFile(path.join(templateDir, 'slack', 'debug.json'), `{
  "blocks": [
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "\`\`\`${expressions.join('\\n')}\`\`\`"
      }
    }
  ]
}`),
fs.writeFile(path.join(templateDir, 'telegram', 'debug.html'), `<pre><code>
${expressions.join('\n')}
</code></pre>`),
fs.writeFile(path.join(templateDir, 'telegram', 'debug.md'), `\`\`\`
${expressions.join('\n')}
\`\`\``),
fs.writeFile(path.join(templateDir, 'telegram', 'debug.txt'), expressions.join('\n')),
)
await Promise.all(jobs)
