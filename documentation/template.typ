#let todo = text.with(red)
#let todo_image(content, width: 10cm, height: 10cm) = {
  rect(width: width, height: height, stroke: red)[
    #v(1fr)
    #todo(content)
    #v(1fr)
  ]
}

#let titlepage(title, subtitle, author, consulents, date, department) = {
  page(numbering: none)[
    #set par(justify: false)
    #set text(hyphenate: false)
    #align(center)[
      #image("bme_logo.pdf", width: 40%)
      *Budapesti Műszaki és Gazdaságtudományi Egyetem*\
      Villamosmérnöki és Informatikai Kar\
      #department
      #v(1fr)
      #block(width: 90%, below: 2em, text(size: 2em, weight: "bold", title))
      #text(size: 1.5em)[#smallcaps(subtitle)]
      #v(0.7fr)
      #grid(
        columns: (1fr, 1fr),
        [
          _Készítette_\
          #author
        ],
        [
          _Konzulens_\
          #consulents.join(linebreak())
        ],
      )
      #v(1.3fr)
      #date
    ]
  ]
}

#let student_statement(student, date) = {
  page(
//    numbering: none
  )[
    #align(center)[
      #text(size: 1.1em)[
        *HALLGATÓI NYILATKOZAT*
      ]
    ]
    #v(1em)

    Alulírott #emph(student), szigorló hallgató kijelentem, hogy ezt a
    diplomatervet meg nem engedett segítség nélkül, saját magam készítettem,
    csak a megadott forrásokat (szakirodalom, eszközök stb.) használtam fel.
    Minden olyan részt, melyet szó szerint, vagy azonos értelemben, de
    átfogalmazva más forrásból átvettem, egyértelműen, a forrás megadásával
    megjelöltem. A Függelékben egyértelműen megjelöltem, hogy a mesterséges
    intelligencia eszközeit alkalmaztam-e a dolgozat elkészítéséhez; amennyiben
    igen, annak módját és mértékét a táblázatban közöltem. Tudomásul veszem,
    hogy a mesterséges intelligenciával generált tartalomért -- annak mértékétől
    függetlenül -- teljes felelősséggel tartozom.

    Hozzájárulok, hogy a jelen munkám alapadatait (szerző(k), cím, angol és
    magyar nyelvű tartalmi kivonat, készítés éve, konzulens(ek) neve) a BME VIK
    nyilvánosan hozzáférhető elektronikus formában, a munka teljes szövege pedig
    a BME Címtárban regisztrált személyek számára elérhető legyen. Kijelentem,
    hogy a benyújtott munka és annak elektronikus verziója megegyezik.
    Dékáni engedéllyel titkosított diplomatervek esetén a dolgozat szövege csak
    3 év eltelte után válik hozzáférhetővé.

    #v(3em)
    Budapest, #date
    #v(3em)
    #align(end)[
      #box[
        #align(center)[
          #line(length: 6cm)
          #emph(student)\
          hallgató
        ]
      ]
      #h(1em)
    ]
  ]
}

#let format(body) = {
  set text(font: "New Computer Modern", size: 12pt, lang: "hu", region: "hu")//, top-edge: 0.8em, bottom-edge: -0.2em) // New Computer Modern
  set page(
    paper: "a4",
    margin: (left: 3.5cm, rest: 2.5cm),
    numbering: "1",
  )

  show figure.caption: it => [#it.counter.display(). #it.supplement: #it.body]
  show figure.where(kind: image): set figure(supplement: [ábra])
  show figure.where(kind: raw): set figure(supplement: [kódrészlet])
  show figure.where(kind: table): set figure(supplement: [táblázat])
  
  set ref(supplement: none)
  //show ref: it => repr(it) // TODO pont a fejezet és figure referenciák után

  set outline(indent: auto)
  set outline.entry(fill: repeat(gap: 0.5em)[.])
  show outline.entry.where(level: 1): it => {
    let entry = outline.entry(1, it.element, fill: [])
    v(0.5em)
    strong(
      link(
        entry.element.location(),
        entry.indented(entry.prefix(), entry.inner()),
      ),
    )
  }

  set heading(numbering: "1.1.")
  show heading: set block(below: 1.0em, above: 1.5em)
  show heading.where(level: 1): it => {
    set par(first-line-indent: (amount: 0em), spacing: 1em)
    pagebreak(weak: true)
    v(2em)
    if it.numbering != none {
      text(size: 1.25em)[
        #counter(heading).display(it.numbering)
        #it.supplement
      ]
      v(0.5em)
    }
    text(size: 1.5em)[#it.body]
    v(1.5em)
  }

  set par(justify: true, 
  first-line-indent: (amount: 3em, all: true), // 0.50" bekezdés, true: az első bekezdést is kezdje beljebb, ne csak a többit
  leading: 1em, // másfeles sorköz libreofficeban
  spacing: 1.5em, // a másfelesre (1em) még pluszban 0.2cm (=0.5em(?)) paragrafusköz
  )

  show raw: it => {
    let params = (fill: rgb("eeeeee"), radius: 0.3em, outset: 0.3em)
    if it.block {
      block(it, width: 100%, ..params)
    } else {
      box(it, ..params)
    }
  }

  body
}

#let template(
  title: "Cím",
  subtitle: "Diplomaterv",
  student: "Mézga Géza",
  consulent: ("Gézga Méza", "Második Konzulens"),
  department: "Irányítástechnika és Informatika Tanszék",
  date: datetime.today(),
  date_format: auto,
  showtitle: true,
  showoutline: true,
  showstatement: true,
  body,
) = {
  set document(
    author: student,
    date: date,
    title: title,
  )

  show: format

  let formatted_date = date.display(date_format)

  if showtitle {
    titlepage(
      title,
      subtitle,
      student,
      if type(consulent) == array { consulent } else { (consulent,) },
      formatted_date,
      department,
    )
  }

  if showoutline {
    //set page(numbering: none)
    outline()
  }
  if showstatement {
    student_statement(student, formatted_date)
  }
  //counter(page).update(1)

  body
}

#let abstract(body) = {
  set heading(numbering: none)
  body
}

#let appendix(body) = {
  heading(level: 1, numbering: none)[Függelék]
  set heading(offset: 1, numbering: (..numbers) => {
    let nums = numbers.pos()
    let _ = nums.remove(0)
    numbering("A.1.", ..nums)
  })
  counter(heading).update(0)
  body
}

