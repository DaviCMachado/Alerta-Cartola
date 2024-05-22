import fs from 'fs';
import path from 'path';
import cheerio from 'cheerio';
import axios from 'axios';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

axios.get('https://footystats.org/pt/brazil/serie-a/fixtures')
  .then(({ data }) => {
    const $ = cheerio.load(data);

    const elementos = $('.timezone-convert-match-week');
    const jogos = [];

    elementos.each((index, element) => {
        const jogo = {};
        jogo.data = $(element).text();

        const proximoSpan = $(element).next('span');
        if (proximoSpan.attr('data-match-status') === 'suspended') {
            jogo.status = 'Suspended';
        } else {
            jogo.status = 'Not Suspended';
        }
      
        const [diaMes, hora] = jogo.data.split(' ');
        const [dia, mes] = diaMes.split('/');
        const diaInt = parseInt(dia, 10);
        const mesInt = parseInt(mes, 10);
        const novoDia = diaInt - 1;
        let novaHora = hora;

        if (Number(hora.split(':')[0]) < 10) {
          novaHora = (parseInt(hora.split(':')[0], 10) + 12) + ':' + hora.split(':')[1];
        }
        const novaData = `${novoDia.toString().padStart(2, '0')}/${mesInt.toString().padStart(2, '0')} ${novaHora}`;

        jogo.data = novaData;
        if (jogo.status == 'Not Suspended') {
            jogos.push(jogo);
        }
    });

    jogos.sort((a, b) => {
        const [dataA, horaA] = a.data.split(' ');
        const [diaA, mesA] = dataA.split('/');
        const [dataB, horaB] = b.data.split(' ');
        const [diaB, mesB] = dataB.split('/');
        
        if (parseInt(mesA) !== parseInt(mesB)) {
            return parseInt(mesA) - parseInt(mesB);
        }
        if (parseInt(diaA) !== parseInt(diaB)) {
            return parseInt(diaA) - parseInt(diaB);
        }
        return horaA.localeCompare(horaB);
    });

    const jsonJogos = JSON.stringify(jogos, null, 2);
    const assetsDirectory = path.join(__dirname, '..', 'assets');
    const filePath = path.join(assetsDirectory, 'jogos.json');

    fs.writeFile(filePath, jsonJogos, 'utf8', (err) => {
      if (err) {
        console.error('Erro ao escrever o arquivo:', err);
      } else {
        console.log('Arquivo salvo com sucesso como jogos.json');
      }
    });
  })
  .catch(error => {
    console.log(error);
  });
