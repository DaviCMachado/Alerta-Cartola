const fs = require('fs');
const cheerio = require('cheerio');
const axios = require('axios');

axios.get('https://footystats.org/pt/brazil/serie-a/fixtures')
  .then(response => {
    const html = response.data;
    const $ = cheerio.load(html);
    const elementos = $('.timezone-convert-match-week');
    const jogos = []; // Array para armazenar informações de cada jogo

    elementos.each((index, element) => {
        const jogo = {}; // Objeto para armazenar informações de um jogo
        jogo.data = $(element).text();

        // Verificar se o próximo elemento `<span>` tem o atributo `status` com o valor `suspended`
        const proximoSpan = $(element).next('span');
        if (proximoSpan.attr('data-match-status') === 'suspended') {
            jogo.status = 'Suspended';
        } else {
            jogo.status = 'Not Suspended';
        }
      
        // Extrair e adicionar informações do jogo ao objeto
        const [diaMes, hora] = jogo.data.split(' ');
        const [dia, mes] = diaMes.split('/');
        const diaInt = parseInt(dia, 10);
        const mesInt = parseInt(mes, 10);
        const novoDia = diaInt - 1;
        const novaHora = (parseInt(hora.split(':')[0], 10) + 12) + ':' + hora.split(':')[1];
        const novaData = `${novoDia.toString().padStart(2, '0')}/${mesInt.toString().padStart(2, '0')} ${novaHora}`;

        jogo.data = novaData;
        if (jogo.status == 'Not Suspended') {
            jogos.push(jogo);
        }
    });

    // Ordenar os jogos por mês, dia e horário
    jogos.sort((a, b) => {
        // Separar data e hora
        const [dataA, horaA] = a.data.split(' ');
        const [diaA, mesA] = dataA.split('/');
        const [dataB, horaB] = b.data.split(' ');
        const [diaB, mesB] = dataB.split('/');
        
        // Comparar mês
        if (parseInt(mesA) !== parseInt(mesB)) {
            return parseInt(mesA) - parseInt(mesB);
        }
        // Comparar dia
        if (parseInt(diaA) !== parseInt(diaB)) {
            return parseInt(diaA) - parseInt(diaB);
        }
        // Comparar horário
        const [horaAHour, horaAMin] = horaA.split(':');
        const [horaBHour, horaBMin] = horaB.split(':');
        if (parseInt(horaAHour) !== parseInt(horaBHour)) {
            return parseInt(horaAHour) - parseInt(horaBHour);
        }
        return parseInt(horaAMin) - parseInt(horaBMin);
    });

    // Converter o array JSON em uma string JSON
    const jsonJogos = JSON.stringify(jogos, null, 2);

    // Escrever o JSON em um arquivo
    fs.writeFile('jogos.json', jsonJogos, 'utf8', (err) => {
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
