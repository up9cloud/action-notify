import fs from 'fs/promises'
import path from 'path'
import { fileURLToPath  } from 'url'

const templateDir = path.join(path.dirname(fileURLToPath(import.meta.url)), 'template')
const raw = await fs.readFile(path.join(templateDir, 'env.txt'), 'utf8')
// Blank lines in env.txt separate groups
let groups = [[]]
for (const s of raw.split('\n')) {
  if (s.trim() === '') {
    if (groups.at(-1).length) {
      groups.push([])
    }
    continue
  }
  if (s.trim().startsWith('#')) {
    continue
  }
  groups.at(-1).push(s)
}
groups = groups.filter(g => g.length)
// The message is shown once, in the form safe for the format: three copies overflow message size limits
const messageVars = ['GIT_COMMIT_MESSAGE', 'GIT_COMMIT_MESSAGE_ESCAPED', 'GIT_COMMIT_MESSAGE_HTML_ESCAPED']
const groupExpressions = messageVar => groups.map(g => g.flatMap(s => {
  if (s === 'GIT_COMMIT_MESSAGE') {
    return [`${s}: \${${messageVar}}`]
  }
  return messageVars.includes(s) ? [] : [`${s}: \${${s}}`]
}))
const expressions = groupExpressions('GIT_COMMIT_MESSAGE').flat()
const jsonGroups = groupExpressions('GIT_COMMIT_MESSAGE_ESCAPED')
const jsonExpressions = jsonGroups.flat()
const htmlExpressions = groupExpressions('GIT_COMMIT_MESSAGE_HTML_ESCAPED').flat()
// Slack caps a section's text at 3000 chars, so each group gets its own section
const slackSections = jsonGroups.map(g => `    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "\`\`\`${g.join('\\n')}\`\`\`"
      }
    }`).join(',\n')
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
${slackSections}
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
