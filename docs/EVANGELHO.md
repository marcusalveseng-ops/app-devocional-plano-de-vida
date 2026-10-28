# Integração do Evangelho

O responsável pelo produto confirmou em 28 de outubro de 2026 que ainda não possui uma fonte com autorização de uso. A integração permanece desativada. O app exibe essa indisponibilidade de forma explícita e não substitui a leitura por texto gerado ou por leitura de outro dia.

## Configurar depois da autorização

Registrar neste documento o fornecedor, edição, calendário, responsável pela autorização, documento ou contrato aplicável, limites de uso, custo e política de armazenamento. Só então preencher os campos em `iOS/PlanoDeVida/Info.plist`:

| Campo | Finalidade |
|---|---|
| GospelEndpoint | Endpoint HTTPS que responde ao contrato abaixo |
| GospelEdition | Identificador estável da edição autorizada |
| GospelLicenseConfirmed | Habilita a busca apenas após a confirmação dos direitos de exibição |
| GospelAudioAllowed | Habilita leitura por síntese local quando autorizada |
| GospelCacheAllowed | Permite reutilizar a cópia da mesma data quando a fonte autoriza cache |

A solicitação usa `GET`, com `date=AAAA-MM-DD`, `calendar=roman-br` e `edition=identificador`. A data é calculada no fuso local do iPhone. Nenhuma nota, pergunta, identificador pessoal ou conteúdo do plano é enviado.

Resposta esperada, HTTP 200 e JSON:

```json
{
  "date": "2026-11-01",
  "calendar": "roman-br",
  "edition": "identificador-da-edicao-autorizada",
  "reference": "referência bíblica fornecida pela fonte",
  "text": "texto exato autorizado para esta data",
  "sourceName": "nome da fonte",
  "sourceURL": "https://dominio-do-fornecedor.example/leitura"
}
```

O exemplo descreve o formato; não constitui uma leitura litúrgica. O cliente rejeita data diferente, calendário diferente, edição inesperada, campos vazios, origem sem HTTPS e resposta acima de 1 MB. Falhas de rede têm nova tentativa. O áudio recebe exatamente o texto exibido.

O cache usa sessão HTTP efêmera e um arquivo explícito somente quando permitido. Uma cópia de outra data não é apresentada como Evangelho de hoje. Desabilitar o cache remove o arquivo local. Se o fornecedor exigir chave secreta, usar um intermediário restrito: segredos não devem ser incorporados ao aplicativo distribuído.

## Critério de liberação

- Autorização de exibição, leitura em áudio e cache registrada, inclusive para a modalidade comercial escolhida.
- Conferência da leitura em domingos, dias comuns, festas e mudanças de tempo litúrgico do calendário romano no Brasil.
- Conferência de meia-noite no fuso de Brasília e após mudança de fuso.
- Testes de resposta vazia, data incorreta, erro de rede, recuperação e cache permitido.

Os testes atuais usam conteúdo artificial explicitamente marcado como fixture. Eles validam o contrato e a rejeição de respostas incorretas; não validam a exatidão litúrgica de um fornecedor ainda não escolhido.
