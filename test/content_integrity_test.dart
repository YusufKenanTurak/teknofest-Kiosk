import 'package:flutter_test/flutter_test.dart';
import 'package:teknofest_kiosk/data/quiz_catalog.dart';
import 'package:teknofest_kiosk/domain/engineering_field.dart';

void main() {
  test('catalog contains exactly 15 questions, 60 options and 7 results', () {
    QuizCatalog.validate();
    expect(QuizCatalog.questions, hasLength(15));
    expect(
      QuizCatalog.questions.expand((question) => question.options),
      hasLength(60),
    );
    expect(QuizCatalog.results, hasLength(7));
    expect(QuizCatalog.results.keys.toSet(), EngineeringField.values.toSet());
    expect(
      EngineeringField.values.map((field) => field.code),
      unorderedEquals(EngineeringField.validCodes),
    );
    expect(EngineeringField.computer.code, 'B');
    expect(EngineeringField.chemistry.code, 'K');
    expect(EngineeringField.environment.code, 'Ç');
    expect(EngineeringField.mechanical.code, 'M');
    expect(EngineeringField.electrical.code, 'E');
    expect(EngineeringField.industrial.code, 'İ');
    expect(EngineeringField.civil.code, 'N');
  });

  test('start copy matches the approved content exactly', () {
    expect(QuizCatalog.startTitle, 'HANGİ MÜHENDİSLİK DALINA YATKINSIN?');
    expect(
      QuizCatalog.startBody,
      'Merakların, düşünme biçimin ve seçimlerin sana en yakın mühendislik alanını gösterebilir. Soruları cevapla, mühendislik yolculuğundaki rotanı keşfet!',
    );
    expect(QuizCatalog.startActionLabel, 'TESTE BAŞLA');
    expect(QuizCatalog.restartActionLabel, 'TESTİ YENİDEN ÇÖZ');
    expect(
      QuizCatalog.discoverTmkActionLabel,
      "TÜRKİYE'NİN MÜHENDİS KIZLARINI KEŞFET",
    );
  });

  test('every question prompt, option text and field mapping is exact', () {
    const expected = <_ExpectedQuestion>[
      _ExpectedQuestion(
        'Yeni bir teknoloji geliştirirken seni en çok hangisi heyecanlandırır?',
        [
          (
            'Bir cihazın nasıl çalıştığını keşfetmek.',
            EngineeringField.mechanical,
          ),
          (
            'İnsanların hayatını kolaylaştıracak bir uygulama geliştirmek.',
            EngineeringField.computer,
          ),
          (
            'Enerjiyi daha verimli kullanmanın yollarını bulmak.',
            EngineeringField.electrical,
          ),
          (
            'Üretim sürecini daha hızlı ve verimli hale getirmek.',
            EngineeringField.industrial,
          ),
        ],
      ),
      _ExpectedQuestion(
        'Bir şehirde yeni bir yaşam alanı tasarlıyorsun. Senin için en önemli konu hangisi olurdu?',
        [
          ('Binaların güvenli ve dayanıklı olması.', EngineeringField.civil),
          (
            'Enerji tüketiminin mümkün olduğunca azaltılması.',
            EngineeringField.environment,
          ),
          (
            'Ulaşım ve günlük yaşamın daha düzenli işlemesi.',
            EngineeringField.industrial,
          ),
          (
            'Akıllı teknolojilerle yaşamın kolaylaştırılması.',
            EngineeringField.electrical,
          ),
        ],
      ),
      _ExpectedQuestion(
        'Bir laboratuvarda yeni bir ürün geliştireceksin. İlk olarak neyi merak edersin?',
        [
          (
            'Kullanılan maddelerin nasıl tepkimeye girdiğini.',
            EngineeringField.chemistry,
          ),
          (
            'Ürünün üretim sürecinin nasıl optimize edilebileceğini.',
            EngineeringField.industrial,
          ),
          (
            'Ürünün doğaya etkisinin ne olacağını.',
            EngineeringField.environment,
          ),
          (
            'Ürünün hangi mekanik sistemle çalışacağını.',
            EngineeringField.mechanical,
          ),
        ],
      ),
      _ExpectedQuestion(
        'Bir robot tasarlama şansın olsa hangi konuya odaklanırdın?',
        [
          (
            'Robotun hareket mekanizmasını geliştirmeye.',
            EngineeringField.mechanical,
          ),
          (
            'Robotun çevresini algılayabilmesini sağlamaya.',
            EngineeringField.electrical,
          ),
          (
            'Robotun kendi kararlarını verebilmesini sağlayacak sistemi geliştirmeye.',
            EngineeringField.computer,
          ),
          (
            'Robotun üretim sürecini daha verimli hale getirmeye.',
            EngineeringField.industrial,
          ),
        ],
      ),
      _ExpectedQuestion(
        'Bir gölde kirlilik fark ettin. İlk olarak hangisini araştırmak istersin?',
        [
          (
            'Kirliliğin kaynağını ve ekosisteme etkisini.',
            EngineeringField.environment,
          ),
          ('Sudaki maddelerin özelliklerini.', EngineeringField.chemistry),
          (
            'Kirliliği sürekli takip edebilecek bir ölçüm sistemi geliştirmeyi.',
            EngineeringField.electrical,
          ),
          (
            'Kirlilik verilerini analiz ederek değişimi takip etmeyi.',
            EngineeringField.computer,
          ),
        ],
      ),
      _ExpectedQuestion(
        'Bir binanın tasarımında seni en çok hangi konu ilgilendirir?',
        [
          (
            'Binanın taşıyıcı sisteminin güvenli olması.',
            EngineeringField.civil,
          ),
          (
            'Binanın enerji sistemlerinin verimli çalışması.',
            EngineeringField.electrical,
          ),
          (
            'Kullanılan malzemelerin özellikleri ve dayanıklılığı.',
            EngineeringField.chemistry,
          ),
          (
            'Binanın çevreye etkisini en aza indirmek.',
            EngineeringField.environment,
          ),
        ],
      ),
      _ExpectedQuestion(
        'Bir uygulamanın sürekli hata verdiğini düşün. Ne yaparsın?',
        [
          (
            'Sorunu adım adım analiz edip hatanın kaynağını bulurum.',
            EngineeringField.computer,
          ),
          (
            'Kullanıcıların uygulamayı nasıl kullandığını incelerim.',
            EngineeringField.industrial,
          ),
          (
            'Sistemin elektronik ve donanım tarafını kontrol ederim.',
            EngineeringField.electrical,
          ),
          (
            'Uygulamanın daha hızlı çalışması için sistemi yeniden tasarlarım.',
            EngineeringField.mechanical,
          ),
        ],
      ),
      _ExpectedQuestion(
        'Bir fabrikanın daha sürdürülebilir hale getirilmesi isteniyor. Sen hangi konuya odaklanırsın?',
        [
          (
            'Atıkların azaltılması ve doğru şekilde yönetilmesine.',
            EngineeringField.environment,
          ),
          (
            'Üretimde kullanılan maddelerin daha verimli kullanılmasına.',
            EngineeringField.chemistry,
          ),
          (
            'Üretim hattının daha verimli çalışmasına.',
            EngineeringField.industrial,
          ),
          (
            'Makinelerin daha az enerji harcamasına.',
            EngineeringField.mechanical,
          ),
        ],
      ),
      _ExpectedQuestion(
        'Bir ürün tasarlarken senin için hangisi daha önemli olurdu?',
        [
          (
            'Kullanıcının ürünü kolay ve rahat kullanması.',
            EngineeringField.industrial,
          ),
          (
            'Ürünün mekanik olarak sağlam ve işlevsel olması.',
            EngineeringField.mechanical,
          ),
          (
            'Ürünün çevreye mümkün olduğunca az zarar vermesi.',
            EngineeringField.environment,
          ),
          (
            'Ürünün elektronik sistemlerinin doğru çalışması.',
            EngineeringField.electrical,
          ),
        ],
      ),
      _ExpectedQuestion(
        'Geleceğin şehirlerinde hangi fikri geliştirmek seni daha çok heyecanlandırır?',
        [
          (
            'Trafiği yapay zekâ ile yöneten akıllı sistemler.',
            EngineeringField.computer,
          ),
          (
            'Doğal kaynakları koruyan sürdürülebilir şehir sistemleri.',
            EngineeringField.environment,
          ),
          (
            'Deprem gibi afetlere karşı daha dayanıklı yapılar.',
            EngineeringField.civil,
          ),
          (
            'Yenilenebilir enerjiyle çalışan akıllı altyapılar.',
            EngineeringField.electrical,
          ),
        ],
      ),
      _ExpectedQuestion(
        'Bir deneyin sonucu beklediğin gibi çıkmadı. İlk tepkin ne olur?',
        [
          (
            'Deneyi farklı maddeler ve koşullarla tekrar denerim.',
            EngineeringField.chemistry,
          ),
          (
            'Sonuçları veriler üzerinden karşılaştırırım.',
            EngineeringField.computer,
          ),
          (
            'Deneyin çevresel etkilerini ve ortaya çıkan atıkları incelerim.',
            EngineeringField.environment,
          ),
          (
            'Deney sistemindeki mekanik düzenekleri kontrol ederim.',
            EngineeringField.mechanical,
          ),
        ],
      ),
      _ExpectedQuestion(
        'Bir problemle karşılaştığında seni en iyi anlatan yaklaşım hangisi?',
        [
          (
            '“Bu sistemi daha sağlam nasıl hale getirebilirim?”',
            EngineeringField.civil,
          ),
          (
            '“Bunu daha hızlı ve verimli nasıl yapabilirim?”',
            EngineeringField.industrial,
          ),
          ('“Bunu teknolojiyle nasıl çözebilirim?”', EngineeringField.computer),
          (
            '“Enerjiyi daha verimli nasıl kullanabilirim?”',
            EngineeringField.electrical,
          ),
        ],
      ),
      _ExpectedQuestion(
        'Yeni bir ürünün geliştirme sürecinde hangi aşama sana daha ilgi çekici gelir?',
        [
          (
            'Ürünün hangi maddelerden oluşacağını belirlemek.',
            EngineeringField.chemistry,
          ),
          ('Ürünün üretim hattını tasarlamak.', EngineeringField.industrial),
          (
            'Ürünün doğaya bıraktığı etkiyi azaltmak.',
            EngineeringField.environment,
          ),
          (
            'Ürünün fiziksel yapısını ve çalışma mekanizmasını geliştirmek.',
            EngineeringField.mechanical,
          ),
        ],
      ),
      _ExpectedQuestion(
        'Bir mühendis olarak dünyada hangi probleme çözüm üretmek isterdin?',
        [
          (
            'Daha güvenli ve dayanıklı yapılar geliştirmek.',
            EngineeringField.civil,
          ),
          (
            'İnsanların hayatını kolaylaştıracak yeni dijital çözümler üretmek.',
            EngineeringField.computer,
          ),
          (
            'Daha temiz ve verimli enerji teknolojileri geliştirmek.',
            EngineeringField.electrical,
          ),
          (
            'İklim ve çevre sorunlarına sürdürülebilir çözümler üretmek.',
            EngineeringField.environment,
          ),
        ],
      ),
      _ExpectedQuestion(
        'Kendine bir proje seçmen gerekse hangisini tercih ederdin?',
        [
          (
            'Yeni nesil bir makine veya robot tasarlamak.',
            EngineeringField.mechanical,
          ),
          (
            'Yeni bir malzeme veya kimyasal ürün geliştirmek.',
            EngineeringField.chemistry,
          ),
          (
            'Depreme dayanıklı yeni nesil bir yapı sistemi tasarlamak.',
            EngineeringField.civil,
          ),
          (
            'Büyük bir sistemin işleyişini analiz ederek daha verimli hale getirmek.',
            EngineeringField.industrial,
          ),
        ],
      ),
    ];

    expect(expected, hasLength(15));

    for (var i = 0; i < expected.length; i++) {
      final question = QuizCatalog.questions[i];
      final want = expected[i];
      expect(question.heading, 'SORU ${i + 1}');
      expect(
        question.prompt,
        want.prompt,
        reason: 'prompt mismatch at SORU ${i + 1}',
      );
      expect(question.options, hasLength(4));
      const labels = ['A', 'B', 'C', 'D'];
      for (var o = 0; o < 4; o++) {
        expect(question.options[o].label, labels[o]);
        expect(
          question.options[o].text,
          want.options[o].$1,
          reason: 'option ${labels[o]} text mismatch at SORU ${i + 1}',
        );
        expect(
          question.options[o].field,
          want.options[o].$2,
          reason: 'option ${labels[o]} field mismatch at SORU ${i + 1}',
        );
      }
    }
  });

  test('seven result screens match the approved copy exactly', () {
    _expectResult(
      EngineeringField.computer,
      emoji: '💻',
      title: 'Bilgisayar Mühendisliği',
      description:
          'Problemlere farklı açılardan bakıyor, teknolojiyle çözüm üretmekten keyif alıyorsun. Kodlar, algoritmalar ve dijital dünyayı şekillendirmek sana göre olabilir.',
      slogan: 'Geleceği kodla, çözümünü yarat!',
    );
    _expectResult(
      EngineeringField.chemistry,
      emoji: '🧪',
      title: 'Kimya Mühendisliği',
      description:
          'Merak ediyor, deniyor, gözlemliyor ve “neden?” sorusunun peşinden gidiyorsun. Maddelerin dünyasını keşfetmek ve yeni çözümler üretmek sana göre olabilir.',
      slogan: 'Keşfet, dönüştür, geleceği üret!',
    );
    _expectResult(
      EngineeringField.environment,
      emoji: '🌱',
      title: 'Çevre Mühendisliği',
      description:
          'Doğayı, kaynakları ve sürdürülebilir yaşamı önemsiyor; problemlere bütünsel çözümler bulmayı seviyorsun.',
      slogan: 'Daha iyi bir gelecek için dünyayı dönüştür!',
    );
    _expectResult(
      EngineeringField.mechanical,
      emoji: '⚙️',
      title: 'Makine Mühendisliği',
      description:
          'Bir şeyin nasıl çalıştığını merak ediyor, parçaları bir araya getirerek yeni şeyler tasarlamaktan hoşlanıyorsun.',
      slogan: 'Tasarla, üret, harekete geçir!',
    );
    _expectResult(
      EngineeringField.electrical,
      emoji: '⚡',
      title: 'Elektrik-Elektronik Mühendisliği',
      description:
          'Enerji, teknoloji ve elektronik sistemlerin nasıl çalıştığını merak ediyorsun. Karmaşık sistemleri çözmek ve yeni teknolojiler geliştirmek sana göre olabilir.',
      slogan: 'Enerjini geleceğe bağla!',
    );
    _expectResult(
      EngineeringField.industrial,
      emoji: '📊',
      title: 'Endüstri Mühendisliği',
      description:
          'Büyük resmi görmeyi, sistemleri analiz etmeyi ve işleri daha iyi, hızlı ve verimli hale getirmeyi seviyorsun.',
      slogan: 'Sistemi gör, çözümü geliştir!',
    );
    _expectResult(
      EngineeringField.civil,
      emoji: '️',
      title: 'İnşaat Mühendisliği',
      description:
          'Bir fikrin gerçeğe dönüşmesini görmek, sağlam ve güvenli yapılar tasarlamak ilgini çekiyor.',
      slogan: 'Sağlam temellerle geleceği inşa et!',
    );
  });
}

void _expectResult(
  EngineeringField field, {
  required String emoji,
  required String title,
  required String description,
  required String slogan,
}) {
  final content = QuizCatalog.resultFor(field);
  expect(content.emoji, emoji, reason: 'emoji mismatch for $field');
  expect(content.title, title, reason: 'title mismatch for $field');
  expect(
    content.description,
    description,
    reason: 'description mismatch for $field',
  );
  expect(content.slogan, slogan, reason: 'slogan mismatch for $field');
}

class _ExpectedQuestion {
  const _ExpectedQuestion(this.prompt, this.options);

  final String prompt;
  final List<(String, EngineeringField)> options;
}
