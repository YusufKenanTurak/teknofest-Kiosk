import '../domain/engineering_field.dart';
import '../domain/models.dart';

/// Approved kiosk copy. Do not rewrite, shorten, or “fix” these strings.
class QuizCatalog {
  const QuizCatalog._();

  static const String startTitle = 'HANGİ MÜHENDİSLİK DALINA YATKINSIN?';

  static const String startBody =
      'Merakların, düşünme biçimin ve seçimlerin sana en yakın mühendislik alanını gösterebilir. Soruları cevapla, mühendislik yolculuğundaki rotanı keşfet!';

  static const String startActionLabel = 'TESTE BAŞLA';

  static const String restartActionLabel = 'TESTİ YENİDEN ÇÖZ';

  static const String discoverTmkActionLabel =
      "TÜRKİYE'NİN MÜHENDİS KIZLARINI KEŞFET";

  static const List<Question> questions = [
    Question(
      number: 1,
      prompt:
          'Yeni bir teknoloji geliştirirken seni en çok hangisi heyecanlandırır?',
      options: [
        AnswerOption(
          label: 'A',
          text: 'Bir cihazın nasıl çalıştığını keşfetmek.',
          field: EngineeringField.mechanical,
        ),
        AnswerOption(
          label: 'B',
          text: 'İnsanların hayatını kolaylaştıracak bir uygulama geliştirmek.',
          field: EngineeringField.computer,
        ),
        AnswerOption(
          label: 'C',
          text: 'Enerjiyi daha verimli kullanmanın yollarını bulmak.',
          field: EngineeringField.electrical,
        ),
        AnswerOption(
          label: 'D',
          text: 'Üretim sürecini daha hızlı ve verimli hale getirmek.',
          field: EngineeringField.industrial,
        ),
      ],
    ),
    Question(
      number: 2,
      prompt:
          'Bir şehirde yeni bir yaşam alanı tasarlıyorsun. Senin için en önemli konu hangisi olurdu?',
      options: [
        AnswerOption(
          label: 'A',
          text: 'Binaların güvenli ve dayanıklı olması.',
          field: EngineeringField.civil,
        ),
        AnswerOption(
          label: 'B',
          text: 'Enerji tüketiminin mümkün olduğunca azaltılması.',
          field: EngineeringField.environment,
        ),
        AnswerOption(
          label: 'C',
          text: 'Ulaşım ve günlük yaşamın daha düzenli işlemesi.',
          field: EngineeringField.industrial,
        ),
        AnswerOption(
          label: 'D',
          text: 'Akıllı teknolojilerle yaşamın kolaylaştırılması.',
          field: EngineeringField.electrical,
        ),
      ],
    ),
    Question(
      number: 3,
      prompt:
          'Bir laboratuvarda yeni bir ürün geliştireceksin. İlk olarak neyi merak edersin?',
      options: [
        AnswerOption(
          label: 'A',
          text: 'Kullanılan maddelerin nasıl tepkimeye girdiğini.',
          field: EngineeringField.chemistry,
        ),
        AnswerOption(
          label: 'B',
          text: 'Ürünün üretim sürecinin nasıl optimize edilebileceğini.',
          field: EngineeringField.industrial,
        ),
        AnswerOption(
          label: 'C',
          text: 'Ürünün doğaya etkisinin ne olacağını.',
          field: EngineeringField.environment,
        ),
        AnswerOption(
          label: 'D',
          text: 'Ürünün hangi mekanik sistemle çalışacağını.',
          field: EngineeringField.mechanical,
        ),
      ],
    ),
    Question(
      number: 4,
      prompt: 'Bir robot tasarlama şansın olsa hangi konuya odaklanırdın?',
      options: [
        AnswerOption(
          label: 'A',
          text: 'Robotun hareket mekanizmasını geliştirmeye.',
          field: EngineeringField.mechanical,
        ),
        AnswerOption(
          label: 'B',
          text: 'Robotun çevresini algılayabilmesini sağlamaya.',
          field: EngineeringField.electrical,
        ),
        AnswerOption(
          label: 'C',
          text:
              'Robotun kendi kararlarını verebilmesini sağlayacak sistemi geliştirmeye.',
          field: EngineeringField.computer,
        ),
        AnswerOption(
          label: 'D',
          text: 'Robotun üretim sürecini daha verimli hale getirmeye.',
          field: EngineeringField.industrial,
        ),
      ],
    ),
    Question(
      number: 5,
      prompt:
          'Bir gölde kirlilik fark ettin. İlk olarak hangisini araştırmak istersin?',
      options: [
        AnswerOption(
          label: 'A',
          text: 'Kirliliğin kaynağını ve ekosisteme etkisini.',
          field: EngineeringField.environment,
        ),
        AnswerOption(
          label: 'B',
          text: 'Sudaki maddelerin özelliklerini.',
          field: EngineeringField.chemistry,
        ),
        AnswerOption(
          label: 'C',
          text:
              'Kirliliği sürekli takip edebilecek bir ölçüm sistemi geliştirmeyi.',
          field: EngineeringField.electrical,
        ),
        AnswerOption(
          label: 'D',
          text: 'Kirlilik verilerini analiz ederek değişimi takip etmeyi.',
          field: EngineeringField.computer,
        ),
      ],
    ),
    Question(
      number: 6,
      prompt: 'Bir binanın tasarımında seni en çok hangi konu ilgilendirir?',
      options: [
        AnswerOption(
          label: 'A',
          text: 'Binanın taşıyıcı sisteminin güvenli olması.',
          field: EngineeringField.civil,
        ),
        AnswerOption(
          label: 'B',
          text: 'Binanın enerji sistemlerinin verimli çalışması.',
          field: EngineeringField.electrical,
        ),
        AnswerOption(
          label: 'C',
          text: 'Kullanılan malzemelerin özellikleri ve dayanıklılığı.',
          field: EngineeringField.chemistry,
        ),
        AnswerOption(
          label: 'D',
          text: 'Binanın çevreye etkisini en aza indirmek.',
          field: EngineeringField.environment,
        ),
      ],
    ),
    Question(
      number: 7,
      prompt: 'Bir uygulamanın sürekli hata verdiğini düşün. Ne yaparsın?',
      options: [
        AnswerOption(
          label: 'A',
          text: 'Sorunu adım adım analiz edip hatanın kaynağını bulurum.',
          field: EngineeringField.computer,
        ),
        AnswerOption(
          label: 'B',
          text: 'Kullanıcıların uygulamayı nasıl kullandığını incelerim.',
          field: EngineeringField.industrial,
        ),
        AnswerOption(
          label: 'C',
          text: 'Sistemin elektronik ve donanım tarafını kontrol ederim.',
          field: EngineeringField.electrical,
        ),
        AnswerOption(
          label: 'D',
          text:
              'Uygulamanın daha hızlı çalışması için sistemi yeniden tasarlarım.',
          field: EngineeringField.mechanical,
        ),
      ],
    ),
    Question(
      number: 8,
      prompt:
          'Bir fabrikanın daha sürdürülebilir hale getirilmesi isteniyor. Sen hangi konuya odaklanırsın?',
      options: [
        AnswerOption(
          label: 'A',
          text: 'Atıkların azaltılması ve doğru şekilde yönetilmesine.',
          field: EngineeringField.environment,
        ),
        AnswerOption(
          label: 'B',
          text: 'Üretimde kullanılan maddelerin daha verimli kullanılmasına.',
          field: EngineeringField.chemistry,
        ),
        AnswerOption(
          label: 'C',
          text: 'Üretim hattının daha verimli çalışmasına.',
          field: EngineeringField.industrial,
        ),
        AnswerOption(
          label: 'D',
          text: 'Makinelerin daha az enerji harcamasına.',
          field: EngineeringField.mechanical,
        ),
      ],
    ),
    Question(
      number: 9,
      prompt: 'Bir ürün tasarlarken senin için hangisi daha önemli olurdu?',
      options: [
        AnswerOption(
          label: 'A',
          text: 'Kullanıcının ürünü kolay ve rahat kullanması.',
          field: EngineeringField.industrial,
        ),
        AnswerOption(
          label: 'B',
          text: 'Ürünün mekanik olarak sağlam ve işlevsel olması.',
          field: EngineeringField.mechanical,
        ),
        AnswerOption(
          label: 'C',
          text: 'Ürünün çevreye mümkün olduğunca az zarar vermesi.',
          field: EngineeringField.environment,
        ),
        AnswerOption(
          label: 'D',
          text: 'Ürünün elektronik sistemlerinin doğru çalışması.',
          field: EngineeringField.electrical,
        ),
      ],
    ),
    Question(
      number: 10,
      prompt:
          'Geleceğin şehirlerinde hangi fikri geliştirmek seni daha çok heyecanlandırır?',
      options: [
        AnswerOption(
          label: 'A',
          text: 'Trafiği yapay zekâ ile yöneten akıllı sistemler.',
          field: EngineeringField.computer,
        ),
        AnswerOption(
          label: 'B',
          text: 'Doğal kaynakları koruyan sürdürülebilir şehir sistemleri.',
          field: EngineeringField.environment,
        ),
        AnswerOption(
          label: 'C',
          text: 'Deprem gibi afetlere karşı daha dayanıklı yapılar.',
          field: EngineeringField.civil,
        ),
        AnswerOption(
          label: 'D',
          text: 'Yenilenebilir enerjiyle çalışan akıllı altyapılar.',
          field: EngineeringField.electrical,
        ),
      ],
    ),
    Question(
      number: 11,
      prompt: 'Bir deneyin sonucu beklediğin gibi çıkmadı. İlk tepkin ne olur?',
      options: [
        AnswerOption(
          label: 'A',
          text: 'Deneyi farklı maddeler ve koşullarla tekrar denerim.',
          field: EngineeringField.chemistry,
        ),
        AnswerOption(
          label: 'B',
          text: 'Sonuçları veriler üzerinden karşılaştırırım.',
          field: EngineeringField.computer,
        ),
        AnswerOption(
          label: 'C',
          text:
              'Deneyin çevresel etkilerini ve ortaya çıkan atıkları incelerim.',
          field: EngineeringField.environment,
        ),
        AnswerOption(
          label: 'D',
          text: 'Deney sistemindeki mekanik düzenekleri kontrol ederim.',
          field: EngineeringField.mechanical,
        ),
      ],
    ),
    Question(
      number: 12,
      prompt:
          'Bir problemle karşılaştığında seni en iyi anlatan yaklaşım hangisi?',
      options: [
        AnswerOption(
          label: 'A',
          text: '“Bu sistemi daha sağlam nasıl hale getirebilirim?”',
          field: EngineeringField.civil,
        ),
        AnswerOption(
          label: 'B',
          text: '“Bunu daha hızlı ve verimli nasıl yapabilirim?”',
          field: EngineeringField.industrial,
        ),
        AnswerOption(
          label: 'C',
          text: '“Bunu teknolojiyle nasıl çözebilirim?”',
          field: EngineeringField.computer,
        ),
        AnswerOption(
          label: 'D',
          text: '“Enerjiyi daha verimli nasıl kullanabilirim?”',
          field: EngineeringField.electrical,
        ),
      ],
    ),
    Question(
      number: 13,
      prompt:
          'Yeni bir ürünün geliştirme sürecinde hangi aşama sana daha ilgi çekici gelir?',
      options: [
        AnswerOption(
          label: 'A',
          text: 'Ürünün hangi maddelerden oluşacağını belirlemek.',
          field: EngineeringField.chemistry,
        ),
        AnswerOption(
          label: 'B',
          text: 'Ürünün üretim hattını tasarlamak.',
          field: EngineeringField.industrial,
        ),
        AnswerOption(
          label: 'C',
          text: 'Ürünün doğaya bıraktığı etkiyi azaltmak.',
          field: EngineeringField.environment,
        ),
        AnswerOption(
          label: 'D',
          text:
              'Ürünün fiziksel yapısını ve çalışma mekanizmasını geliştirmek.',
          field: EngineeringField.mechanical,
        ),
      ],
    ),
    Question(
      number: 14,
      prompt:
          'Bir mühendis olarak dünyada hangi probleme çözüm üretmek isterdin?',
      options: [
        AnswerOption(
          label: 'A',
          text: 'Daha güvenli ve dayanıklı yapılar geliştirmek.',
          field: EngineeringField.civil,
        ),
        AnswerOption(
          label: 'B',
          text:
              'İnsanların hayatını kolaylaştıracak yeni dijital çözümler üretmek.',
          field: EngineeringField.computer,
        ),
        AnswerOption(
          label: 'C',
          text: 'Daha temiz ve verimli enerji teknolojileri geliştirmek.',
          field: EngineeringField.electrical,
        ),
        AnswerOption(
          label: 'D',
          text: 'İklim ve çevre sorunlarına sürdürülebilir çözümler üretmek.',
          field: EngineeringField.environment,
        ),
      ],
    ),
    Question(
      number: 15,
      prompt: 'Kendine bir proje seçmen gerekse hangisini tercih ederdin?',
      options: [
        AnswerOption(
          label: 'A',
          text: 'Yeni nesil bir makine veya robot tasarlamak.',
          field: EngineeringField.mechanical,
        ),
        AnswerOption(
          label: 'B',
          text: 'Yeni bir malzeme veya kimyasal ürün geliştirmek.',
          field: EngineeringField.chemistry,
        ),
        AnswerOption(
          label: 'C',
          text: 'Depreme dayanıklı yeni nesil bir yapı sistemi tasarlamak.',
          field: EngineeringField.civil,
        ),
        AnswerOption(
          label: 'D',
          text:
              'Büyük bir sistemin işleyişini analiz ederek daha verimli hale getirmek.',
          field: EngineeringField.industrial,
        ),
      ],
    ),
  ];

  static const Map<EngineeringField, FieldResultContent> results = {
    EngineeringField.computer: FieldResultContent(
      field: EngineeringField.computer,
      emoji: '💻',
      title: 'Bilgisayar Mühendisliği',
      description:
          'Problemlere farklı açılardan bakıyor, teknolojiyle çözüm üretmekten keyif alıyorsun. Kodlar, algoritmalar ve dijital dünyayı şekillendirmek sana göre olabilir.',
      slogan: 'Geleceği kodla, çözümünü yarat!',
    ),
    EngineeringField.chemistry: FieldResultContent(
      field: EngineeringField.chemistry,
      emoji: '🧪',
      title: 'Kimya Mühendisliği',
      description:
          'Merak ediyor, deniyor, gözlemliyor ve “neden?” sorusunun peşinden gidiyorsun. Maddelerin dünyasını keşfetmek ve yeni çözümler üretmek sana göre olabilir.',
      slogan: 'Keşfet, dönüştür, geleceği üret!',
    ),
    EngineeringField.environment: FieldResultContent(
      field: EngineeringField.environment,
      emoji: '🌱',
      title: 'Çevre Mühendisliği',
      description:
          'Doğayı, kaynakları ve sürdürülebilir yaşamı önemsiyor; problemlere bütünsel çözümler bulmayı seviyorsun.',
      slogan: 'Daha iyi bir gelecek için dünyayı dönüştür!',
    ),
    EngineeringField.mechanical: FieldResultContent(
      field: EngineeringField.mechanical,
      emoji: '⚙️',
      title: 'Makine Mühendisliği',
      description:
          'Bir şeyin nasıl çalıştığını merak ediyor, parçaları bir araya getirerek yeni şeyler tasarlamaktan hoşlanıyorsun.',
      slogan: 'Tasarla, üret, harekete geçir!',
    ),
    EngineeringField.electrical: FieldResultContent(
      field: EngineeringField.electrical,
      emoji: '⚡',
      title: 'Elektrik-Elektronik Mühendisliği',
      description:
          'Enerji, teknoloji ve elektronik sistemlerin nasıl çalıştığını merak ediyorsun. Karmaşık sistemleri çözmek ve yeni teknolojiler geliştirmek sana göre olabilir.',
      slogan: 'Enerjini geleceğe bağla!',
    ),
    EngineeringField.industrial: FieldResultContent(
      field: EngineeringField.industrial,
      emoji: '📊',
      title: 'Endüstri Mühendisliği',
      description:
          'Büyük resmi görmeyi, sistemleri analiz etmeyi ve işleri daha iyi, hızlı ve verimli hale getirmeyi seviyorsun.',
      slogan: 'Sistemi gör, çözümü geliştir!',
    ),
    EngineeringField.civil: FieldResultContent(
      field: EngineeringField.civil,
      emoji: '️',
      title: 'İnşaat Mühendisliği',
      description:
          'Bir fikrin gerçeğe dönüşmesini görmek, sağlam ve güvenli yapılar tasarlamak ilgini çekiyor.',
      slogan: 'Sağlam temellerle geleceği inşa et!',
    ),
  };

  static FieldResultContent resultFor(EngineeringField field) {
    final content = results[field];
    if (content == null) {
      throw StateError('Missing result content for $field');
    }
    return content;
  }

  static void validate() {
    if (questions.length != 15) {
      throw StateError('Quiz must contain exactly 15 questions.');
    }
    if (results.length != EngineeringField.values.length) {
      throw StateError('Each engineering field must have result content.');
    }

    final numbers = <int>{};
    final labels = <String>['A', 'B', 'C', 'D'];
    for (var i = 0; i < questions.length; i++) {
      final question = questions[i];
      if (question.number != i + 1) {
        throw StateError('Question numbers must be sequential starting at 1.');
      }
      if (!numbers.add(question.number)) {
        throw StateError('Question ${question.number} is duplicated.');
      }
      if (question.prompt.trim().isEmpty) {
        throw StateError('Question ${question.number} is missing a prompt.');
      }
      if (question.options.length != 4) {
        throw StateError('Question ${question.number} must have 4 options.');
      }
      final optionLabels = <String>{};
      for (var o = 0; o < 4; o++) {
        final option = question.options[o];
        if (option.label != labels[o]) {
          throw StateError(
            'Question ${question.number} option ${o + 1} must be ${labels[o]}.',
          );
        }
        if (!optionLabels.add(option.label)) {
          throw StateError(
            'Question ${question.number} has a duplicate option ${option.label}.',
          );
        }
        if (option.text.trim().isEmpty) {
          throw StateError(
            'Question ${question.number} option ${option.label} is empty.',
          );
        }
        if (!EngineeringField.validCodes.contains(option.code)) {
          throw StateError(
            'Question ${question.number} option ${option.label} has an invalid code.',
          );
        }
      }
    }

    final mappedCodes = EngineeringField.values
        .map((field) => field.code)
        .toSet();
    if (mappedCodes.length != EngineeringField.values.length) {
      throw StateError('Engineering field codes must be unique.');
    }
    for (final code in mappedCodes) {
      if (!EngineeringField.validCodes.contains(code)) {
        throw StateError('Unknown engineering field code in mapping.');
      }
    }
    if (mappedCodes.length != EngineeringField.validCodes.length) {
      throw StateError(
        'Engineering field codes must match the approved mapping.',
      );
    }

    for (final field in EngineeringField.values) {
      resultFor(field);
    }
  }
}
