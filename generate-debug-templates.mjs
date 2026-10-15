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
// The raw commit message breaks JSON and HTML, so those show the escaped form for that format instead
const safeExpressions = (messageVar, unsafeVar) => envs
  .filter(s => s !== unsafeVar)
  .map(s => `${s}: \${${s === 'GIT_COMMIT_MESSAGE' ? messageVar : s}}`)
const jsonExpressions = safeExpressions('GIT_COMMIT_MESSAGE_ESCAPED', 'GIT_COMMIT_MESSAGE_HTML_ESCAPED')
const htmlExpressions = safeExpressions('GIT_COMMIT_MESSAGE_HTML_ESCAPED', 'GIT_COMMIT_MESSAGE_ESCAPED')
let jobs = []
jobs.push(
fs.writeFile(path.join(templateDir, 'discord', 'debug.json'), `{
  "tts": false,
  "embeds": [
    {
      "description": "\`\`\`${jsonExpressions.join('\\n')}\`\`\`"
    }
  ]
}`),
fs.writeFile(path.join(templateDir, 'line.me', 'debug.json'), `{
  "messages":[
    {
      "type":"text",
      "text":"${jsonExpressions.join('\\n')}"
    }
  ]
}`),
fs.writeFile(path.join(templateDir, 'slack', 'debug.json'), `{
  "blocks": [
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "\`\`\`${jsonExpressions.join('\\n')}\`\`\`"
      }
    }
  ]
}`),
fs.writeFile(path.join(templateDir, 'telegram', 'debug.html'), `<pre><code>
${htmlExpressions.join('\n')}
</code></pre>`),
fs.writeFile(path.join(templateDir, 'telegram', 'debug.HTML.html'), `<pre><code>
${htmlExpressions.join('\n')}
</code></pre>`),
fs.writeFile(path.join(templateDir, 'telegram', 'debug.md'), `\`\`\`
${expressions.join('\n')}
\`\`\``),
fs.writeFile(path.join(templateDir, 'telegram', 'debug.MarkdownV2.md'), `\`\`\`
${expressions.join('\n')}
\`\`\``),
fs.writeFile(path.join(templateDir, 'telegram', 'debug.txt'), expressions.join('\n')),
)
await Promise.all(jobs)
