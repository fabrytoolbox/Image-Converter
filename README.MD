# 🖼️ Image Converter

Convertitore di immagini a livelli (WebP, PNG, JPEG) con ottimizzazione, sharpening e log.

## ✨ Feature

- ✅ **Formati di output**: WebP Lossless, WebP 90%, PNG ottimizzato, JPEG, Mantieni formato
- ✅ **Sharpening**: Leggero, Medio, Forte, Nessuno (con filtro `unsharp`)
- ✅ **Ricorsivo**: Opzione per includere le sottocartelle
- ✅ **Auto-download FFmpeg** (se non presente)
- ✅ **Log su file** (`image_converter_*.log`)
- ✅ **Statistiche di compressione**: mostra il risparmio (o l'aumento) per ogni file
- ✅ **Interfaccia a livelli**: guidata passo-passo, senza GUI pesante

## 📋 Requisiti

- **Windows 10 / 11**
- **PowerShell 7+** (scarica da https://aka.ms/powershell)
- **FFmpeg** (scaricato automaticamente al primo avvio)

## 🚀 Quick start

```powershell
git clone https://github.com/fabrytoolbox/Image-Converter.git
cd Image-Converter
Unblock-File .\Image-Converter.ps1
.\Image-Converter.ps1

Oppure doppio click su avvia.bat.

🎯 Casi d'uso
Ottimizzare le foto per il web (WebP è più leggero del 30% rispetto a JPEG a parità di qualità)

Convertire in blocco immagini per un sito, un blog o un e-commerce

Ridurre lo spazio occupato da una cartella di foto senza perdere qualità (Lossless)

Standardizzare formati misti (JPG, PNG, BMP) in un unico formato

⚙️ Come funziona
Seleziona la cartella con le immagini

Scegli se includere le sottocartelle

Scegli il formato di output (WebP Lossless è il più consigliato)

Scegli lo sharpening (Leggero è un buon compromesso)

Scegli dove salvare i file (sottocartella Convertiti o stessa cartella)

Lo script converte e mostra il risparmio di spazio per ogni file

🐛 Problemi comuni
"FFmpeg non trovato"
Il tool chiede se scaricarlo. Se il download fallisce, scaricalo manualmente da https://www.gyan.dev/ffmpeg/builds/ e mettilo nella cartella dello script.

"Il file di output è più grande dell'originale"
Può succedere con JPEG (che sono già compressi) o se stai convertendo da formati già ottimizzati. Prova WebP Lossless o PNG.

"Sharpening troppo forte"
Usa "Leggero" o "Nessuno" se le immagini sembrano innaturali.

📜 Licenza
MIT (vedi LICENSE).

🙏 Crediti
FFmpeg per l'elaborazione immagini

Fabry Toolbox