# App - Devocional Plano de Vida

Repositório para acompanhar todo o ciclo de vida do app: definição, desenvolvimento, validação, publicação e manutenção.

## Estado atual

Implementação nativa para iPhone em SwiftUI, com iOS 17 como versão mínima de desenvolvimento. O projeto contém plano visual, catálogo de práticas, repetições semanais, lembretes locais, exame guiado por voz, temporizador, notas locais e bloqueio opcional com autenticação do aparelho.

A fonte do Evangelho permanece pendente de autorização, conforme decisão do responsável pelo produto em 28 de outubro de 2026. O cliente HTTP e a validação de data, edição e calendário estão preparados; o aplicativo informa que a leitura está indisponível enquanto a fonte não for configurada. Textos iniciais de oração e exame ainda precisam de revisão editorial.

O app ainda não foi distribuído na App Store nem instalado em um iPhone físico. Consulte [Validação](docs/VALIDACAO.md) para distinguir testes automatizados de verificações pendentes em aparelho real.

## Executar no iPhone ou no simulador

1. Em um Mac com Xcode 16 ou mais recente, clone este repositório e abra `PlanoDeVida.xcodeproj`.
2. Selecione o esquema **PlanoDeVida** e um simulador de iPhone. Execute com **Run**. Não há dependências externas para baixar.
3. Para usar um iPhone físico, selecione sua equipe em **Signing & Capabilities**, ajuste o identificador do app se necessário e conecte o aparelho. A assinatura depende da sua conta Apple Developer.
4. No primeiro uso, escolha um modelo editável ou um plano vazio. Configure os lembretes dentro das atividades; a permissão é solicitada ao ativar o primeiro.

O Windows permite editar os fontes e gerar o projeto, mas não executa o Xcode ou o simulador de iOS. O workflow [iOS MVP](.github/workflows/ios.yml) prepara a verificação em macOS no GitHub Actions.

## Verificar mudanças

```sh
swift test
python3 scripts/generate-project.py
xcodebuild -project PlanoDeVida.xcodeproj -scheme PlanoDeVida \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

Os testes de interface estão no esquema do Xcode. Escolha um simulador de iPhone e use **Product → Test**. Eles usam um diretório de dados isolado em builds de depuração. O workflow salva logs, resultados e capturas em um artefato privado com retenção de 14 dias.

## Estrutura

```text
Sources/DevotionalCore/       Modelos, regras, persistência e contrato do Evangelho
Tests/DevotionalCoreTests/    Testes do núcleo
iOS/PlanoDeVida/              SwiftUI e serviços nativos de iOS
iOS/PlanoDeVidaUITests/       Fluxos essenciais no simulador
PlanoDeVida.xcodeproj/        Projeto e esquema compartilhado
scripts/generate-project.py  Gerador determinístico do projeto
docs/                        PRD, decisões, conteúdo e validação
```

## Onde registrar cada assunto

- [Roadmap](docs/ROADMAP.md): etapas e próximos resultados esperados.
- [Ciclo de vida](docs/CICLO-DE-VIDA.md): fluxo de trabalho da ideia à manutenção.
- [Decisões](docs/DECISOES.md): escolhas de produto e tecnologia, com suas razões.
- [PRD](docs/PRD.md): transcrição do documento original fornecido pelo responsável pelo produto.
- [Fonte do Evangelho](docs/EVANGELHO.md): contrato de integração e autorização pendente.
- [Conteúdo editorial](docs/CONTEUDO.md): origem e revisão dos textos distribuídos.
- [Validação](docs/VALIDACAO.md): cobertura e roteiro de testes em iPhone.
- [Histórico de alterações](CHANGELOG.md): mudanças entregues por versão.
- Issues do GitHub: funcionalidades, problemas, critérios de aceite e acompanhamento.
- Pull requests: mudanças propostas, validação e vínculo com as issues.
- Releases: versões publicadas e respectivas notas de entrega.

## Dados pessoais

Plano, notas, roteiros e preferências ficam em um arquivo JSON versionado, salvo atomicamente com proteção completa de arquivo do iOS. O diretório é excluído do backup do sistema. Não há sincronização, exportação, conta, telemetria ou envio de texto pessoal para voz externa. Apagar o app ou perder o aparelho pode causar perda dos dados. Uma falha de leitura preserva o arquivo e bloqueia novas gravações para evitar substituição silenciosa.

O fluxo de desenvolvimento e publicação está em [Ciclo de vida](docs/CICLO-DE-VIDA.md). Novas etapas devem gerar commits pequenos após a verificação apropriada.
