# Mori Recorder

Grava pequenos clipes ao longo de uma sessão e permite organizá-los ou combiná-los em um vídeo.

## Versões do projeto

| Branch | Versão | Onde usar |
| --- | --- | --- |
| [`swift-playgrounds`](https://github.com/Rafawaldrigues/Mori-camera/tree/swift-playgrounds) | Aplicativo nativo em Swift/SwiftUI | Swift Playgrounds; base para evolução no Xcode |
| [`beta-safari`](https://github.com/Rafawaldrigues/Mori-camera/tree/beta-safari) | Demonstração web instalável (PWA) | Safari no iPhone, hospedada em VPS com HTTPS |

Esta branch contém a versão **Swift**, atualizada conforme o relatório de 06 de junho. O projeto antigo em Flutter/Dart foi retirado desta versão; seu histórico permanece nos commits anteriores.

## Recursos implementados

- Seleção de zoom conforme os recursos da câmera, com referência inicial em 1x. Alguns atalhos usam zoom digital.
- Proporções 16:9, 4:3 e 1:1, incluindo recorte do arquivo salvo.
- Ajuste de exposição dentro dos limites do aparelho.
- Quantidade de clipes, intervalo, duração e parada automática ao atingir a quantidade.
- Gravação com áudio, sem controle de silenciamento.
- Galeria com “Combinar Vídeos” e “Salvar Separadamente”.
- Exportação local com tratamento de orientação, faixas de áudio e erros de salvamento no Fotos.

## Abrir no Swift Playgrounds

Baixe ou clone esta branch e abra **`MoriRecorder.swiftpm`**, a pasta do projeto, em um ambiente Apple compatível. O manifesto usa `AppleProductTypes` para declarar um aplicativo iOS, não uma biblioteca Swift genérica.

A versão mínima declarada é iOS 15. A execução solicita acesso à câmera, microfone e Fotos.

## Evoluir no Xcode

O código está em `MoriRecorder.swiftpm/Sources/MoriRecorder`. Ao migrar para um projeto iOS App no Xcode:

1. Use Swift e SwiftUI e adicione os arquivos de `Sources/MoriRecorder` ao target.
2. Adicione `Resources/Assets.xcassets` e selecione o `AppIcon`.
3. Mantenha uma única entrada `@main`: `TimeClipApp`. Remova a entrada gerada pelo novo projeto, caso exista.
4. Configure um Bundle Identifier, sua equipe de assinatura e as descrições de uso de câmera, microfone e Fotos.
5. Compile e teste em iPhone físico, principalmente captura, lentes, orientação e exportação.

As permissões do projeto Playgrounds estão declaradas em `Package.swift`. Não é necessário reutilizar o antigo Info.plist do repositório.

## Estado da validação

O código foi revisado, mas **ainda não foi compilado nem executado com Xcode/SDK iOS** no ambiente de edição Linux. Esta branch é a base atualizada para validação no dispositivo; não representa uma versão já homologada para a App Store.

Os controles e a qualidade dependem do modelo do iPhone. A gravação em segundo plano não está garantida. O recorte exige processamento adicional; em caso de falha, o original é preservado e o app informa o problema.

Consulte [alterações e roteiro de testes](MoriRecorder.swiftpm/ALTERACOES.md).

Para testar pelo Safari sem Mac ou iPad, use a [branch beta-safari](https://github.com/Rafawaldrigues/Mori-camera/tree/beta-safari).
