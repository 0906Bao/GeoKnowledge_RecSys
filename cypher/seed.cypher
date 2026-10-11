// GeoKnowledge & RecSys — dữ liệu tứ giác đầy đủ, có thể chạy lại bằng MERGE.
// Chạy schema.cypher trước, sau đó chạy toàn bộ tệp này trong Neo4j Browser.
// Quan hệ IS_A đi từ hình con tới hình cha; chỉ lưu quan hệ cha trực tiếp để đồ thị gọn.

UNWIND [
{id:'quad',name:'Tứ giác',type:'Hình tổng quát',grade:'8',topic:'Tu_giac',sort_order:1,definition:'Tứ giác ABCD là hình gồm bốn đoạn thẳng AB, BC, CD, DA, trong đó hai đoạn thẳng bất kỳ không cùng nằm trên một đường thẳng và các cạnh chỉ gặp nhau tại đầu mút theo thứ tự. Trong nội dung này xét tứ giác lồi.'},
{id:'trapezoid',name:'Hình thang',type:'Hình chính',grade:'8',topic:'Tu_giac',sort_order:2,definition:'Hình thang là tứ giác có ít nhất một cặp cạnh đối song song theo quy ước phân cấp của ứng dụng.'},
{id:'isosceles_trapezoid',name:'Hình thang cân',type:'Hình chính',grade:'8',topic:'Tu_giac',sort_order:3,definition:'Hình thang cân là hình thang có hai góc kề một đáy bằng nhau.'},
{id:'right_trapezoid',name:'Hình thang vuông',type:'Hình chính',grade:'8',topic:'Tu_giac',sort_order:4,definition:'Hình thang vuông là hình thang có một cạnh bên vuông góc với hai đáy; do đó có hai góc vuông.'},
{id:'parallelogram',name:'Hình bình hành',type:'Hình chính',grade:'8',topic:'Tu_giac',sort_order:5,definition:'Hình bình hành là tứ giác có hai cặp cạnh đối song song.'},
{id:'rectangle',name:'Hình chữ nhật',type:'Hình chính',grade:'8',topic:'Tu_giac',sort_order:6,definition:'Hình chữ nhật là tứ giác có bốn góc vuông.'},
{id:'rhombus',name:'Hình thoi',type:'Hình chính',grade:'8',topic:'Tu_giac',sort_order:7,definition:'Hình thoi là tứ giác có bốn cạnh bằng nhau.'},
{id:'square',name:'Hình vuông',type:'Hình chính',grade:'8',topic:'Tu_giac',sort_order:8,definition:'Hình vuông là tứ giác có bốn góc vuông và bốn cạnh bằng nhau.'}
] AS x MERGE (c:Concept {id:x.id}) SET c += x;

// Xóa riêng cạnh phân cấp cũ giữa 8 khái niệm, sau đó tạo hệ thống chuẩn.
MATCH (a:Concept)-[r:IS_A|IS_SPECIAL_CASE_OF]->(b:Concept)
WHERE a.id IN ['quad','trapezoid','isosceles_trapezoid','right_trapezoid','parallelogram','rectangle','rhombus','square']
  AND b.id IN ['quad','trapezoid','isosceles_trapezoid','right_trapezoid','parallelogram','rectangle','rhombus','square']
DELETE r;

UNWIND [
['trapezoid','quad'],['isosceles_trapezoid','trapezoid'],['right_trapezoid','trapezoid'],
['parallelogram','trapezoid'],['rectangle','parallelogram'],['rhombus','parallelogram'],
['square','rectangle'],['square','rhombus']
] AS pair
MATCH (child:Concept {id:pair[0]}),(parent:Concept {id:pair[1]})
MERGE (child)-[:IS_A]->(parent);

UNWIND [
{id:'p_quad_angle',concept:'quad',category:'Góc',content:'Tổng số đo bốn góc trong của một tứ giác lồi bằng 360°.'},
{id:'p_quad_diag',concept:'quad',category:'Đường chéo',content:'Một đường chéo chia tứ giác lồi thành hai tam giác.'},
{id:'p_trap_bases',concept:'trapezoid',category:'Cạnh',content:'Hai cạnh đáy của hình thang song song.'},
{id:'p_trap_angles',concept:'trapezoid',category:'Góc',content:'Hai góc kề cùng một cạnh bên có tổng số đo bằng 180°.'},
{id:'p_trap_rec',concept:'trapezoid',category:'Dấu hiệu nhận biết',content:'Tứ giác có một cặp cạnh đối song song là hình thang theo quy ước của ứng dụng.'},
{id:'p_iso_legs',concept:'isosceles_trapezoid',category:'Cạnh',content:'Hai cạnh bên của hình thang cân bằng nhau.'},
{id:'p_iso_angles',concept:'isosceles_trapezoid',category:'Góc',content:'Hai góc kề mỗi đáy của hình thang cân bằng nhau.'},
{id:'p_iso_diags',concept:'isosceles_trapezoid',category:'Đường chéo',content:'Hai đường chéo của hình thang cân bằng nhau.'},
{id:'p_iso_rec',concept:'isosceles_trapezoid',category:'Dấu hiệu nhận biết',content:'Hình thang có hai góc kề một đáy bằng nhau là hình thang cân.'},
{id:'p_right_angles',concept:'right_trapezoid',category:'Góc',content:'Hình thang vuông có hai góc vuông.'},
{id:'p_right_height',concept:'right_trapezoid',category:'Chiều cao',content:'Cạnh bên vuông góc với hai đáy là chiều cao của hình thang vuông.'},
{id:'p_right_rec',concept:'right_trapezoid',category:'Dấu hiệu nhận biết',content:'Hình thang có một góc vuông là hình thang vuông.'},
{id:'p_para_sides',concept:'parallelogram',category:'Cạnh',content:'Các cạnh đối của hình bình hành song song và bằng nhau.'},
{id:'p_para_angles',concept:'parallelogram',category:'Góc',content:'Các góc đối của hình bình hành bằng nhau; hai góc kề bù nhau.'},
{id:'p_para_diag',concept:'parallelogram',category:'Đường chéo',content:'Hai đường chéo của hình bình hành cắt nhau tại trung điểm mỗi đường.'},
{id:'p_para_rec',concept:'parallelogram',category:'Dấu hiệu nhận biết',content:'Tứ giác có hai cặp cạnh đối song song là hình bình hành. Các dấu hiệu khác gồm hai cặp cạnh đối bằng nhau hoặc hai đường chéo cắt nhau tại trung điểm mỗi đường.'},
{id:'p_rect_angles',concept:'rectangle',category:'Góc',content:'Hình chữ nhật có bốn góc vuông.'},
{id:'p_rect_sides',concept:'rectangle',category:'Cạnh',content:'Các cạnh đối của hình chữ nhật bằng nhau.'},
{id:'p_rect_diags',concept:'rectangle',category:'Đường chéo',content:'Hai đường chéo hình chữ nhật bằng nhau và cắt nhau tại trung điểm mỗi đường.'},
{id:'p_rect_rec',concept:'rectangle',category:'Dấu hiệu nhận biết',content:'Hình bình hành có một góc vuông là hình chữ nhật; hình bình hành có hai đường chéo bằng nhau cũng là hình chữ nhật.'},
{id:'p_rhombus_sides',concept:'rhombus',category:'Cạnh',content:'Bốn cạnh hình thoi bằng nhau; các cạnh đối song song.'},
{id:'p_rhombus_angles',concept:'rhombus',category:'Góc',content:'Các góc đối của hình thoi bằng nhau; hai góc kề bù nhau.'},
{id:'p_rhombus_diags',concept:'rhombus',category:'Đường chéo',content:'Hai đường chéo hình thoi vuông góc, cắt nhau tại trung điểm mỗi đường và là các đường phân giác của góc.'},
{id:'p_rhombus_rec',concept:'rhombus',category:'Dấu hiệu nhận biết',content:'Hình bình hành có hai cạnh kề bằng nhau hoặc có hai đường chéo vuông góc là hình thoi.'},
{id:'p_square_sides',concept:'square',category:'Cạnh',content:'Bốn cạnh hình vuông bằng nhau; hai cặp cạnh đối song song.'},
{id:'p_square_angles',concept:'square',category:'Góc',content:'Bốn góc hình vuông đều là góc vuông.'},
{id:'p_square_diags',concept:'square',category:'Đường chéo',content:'Hai đường chéo hình vuông bằng nhau, vuông góc, cắt nhau tại trung điểm mỗi đường và phân giác các góc.'},
{id:'p_square_rec',concept:'square',category:'Dấu hiệu nhận biết',content:'Hình chữ nhật có hai cạnh kề bằng nhau là hình vuông; hình thoi có một góc vuông là hình vuông.'}
] AS x
MERGE (p:Property {id:x.id}) SET p.category=x.category,p.content=x.content
WITH p,x MATCH (c:Concept {id:x.concept}) MERGE (c)-[:HAS_PROPERTY]->(p);

UNWIND [
{id:'th_quad_angle',concept:'quad',name:'Tổng các góc trong tứ giác',statement:'Tổng số đo bốn góc trong của tứ giác lồi bằng 360°.',conditions:'ABCD là tứ giác lồi.',conclusion:'∠A + ∠B + ∠C + ∠D = 360°.',proof:'Kẻ một đường chéo, tứ giác được chia thành hai tam giác. Tổng góc bằng 180° + 180° = 360°.'},
{id:'th_trap_angles',concept:'trapezoid',name:'Hai góc kề cạnh bên hình thang',statement:'Hai góc trong cùng phía tạo bởi cạnh bên và hai đáy song song có tổng 180°.',conditions:'Hai đáy của hình thang song song.',conclusion:'Hai góc kề một cạnh bên bù nhau.',proof:'Hai góc trong cùng phía tạo bởi một đường cắt hai đường thẳng song song bù nhau.'},
{id:'th_iso_base',concept:'isosceles_trapezoid',name:'Góc đáy hình thang cân',statement:'Hai góc kề mỗi đáy của hình thang cân bằng nhau.',conditions:'ABCD là hình thang cân, AB ∥ CD.',conclusion:'∠A = ∠B và ∠D = ∠C.',proof:'Đây là tính chất cơ bản của hình thang cân.'},
{id:'th_iso_diag',concept:'isosceles_trapezoid',name:'Đường chéo hình thang cân',statement:'Hai đường chéo của hình thang cân bằng nhau.',conditions:'ABCD là hình thang cân.',conclusion:'AC = BD.',proof:'Có thể chứng minh hai tam giác tạo bởi cạnh đáy, cạnh bên và đường chéo bằng nhau theo trường hợp cạnh-góc-cạnh.'},
{id:'th_right_trap',concept:'right_trapezoid',name:'Hai góc vuông của hình thang vuông',statement:'Hình thang vuông có hai góc vuông kề cùng một cạnh bên.',conditions:'ABCD là hình thang và một cạnh bên vuông góc với một đáy.',conclusion:'Cạnh bên đó vuông góc với cả hai đáy; hai góc kề cạnh bên bằng 90°.',proof:'Hai đáy song song; đường thẳng vuông góc với một trong hai đường thẳng song song cũng vuông góc với đường còn lại.'},
{id:'th_para_sides',concept:'parallelogram',name:'Cạnh và góc hình bình hành',statement:'Các cạnh đối của hình bình hành bằng nhau; các góc đối bằng nhau.',conditions:'ABCD là hình bình hành.',conclusion:'AB = CD, AD = BC; ∠A = ∠C, ∠B = ∠D.',proof:'Kẻ đường chéo AC, dùng các cặp góc so le trong và hai tam giác bằng nhau.'},
{id:'th_para_diag',concept:'parallelogram',name:'Đường chéo hình bình hành',statement:'Hai đường chéo hình bình hành cắt nhau tại trung điểm mỗi đường.',conditions:'ABCD là hình bình hành, hai đường chéo AC và BD cắt nhau tại O.',conclusion:'OA = OC và OB = OD.',proof:'Hai tam giác AOB và COD bằng nhau theo góc-cạnh-góc.'},
{id:'th_rect_diag',concept:'rectangle',name:'Đường chéo hình chữ nhật',statement:'Hai đường chéo hình chữ nhật bằng nhau và cắt nhau tại trung điểm mỗi đường.',conditions:'ABCD là hình chữ nhật.',conclusion:'AC = BD; OA = OC và OB = OD.',proof:'Hình chữ nhật là hình bình hành nên hai đường chéo cắt nhau tại trung điểm; các tam giác vuông tương ứng cho thấy hai đường chéo bằng nhau.'},
{id:'th_rhombus_diag',concept:'rhombus',name:'Đường chéo hình thoi',statement:'Hai đường chéo hình thoi vuông góc và là các đường phân giác của các góc.',conditions:'ABCD là hình thoi.',conclusion:'AC ⟂ BD; các đường chéo chia đôi nhau và phân giác góc.',proof:'Dựa vào các cạnh bằng nhau và các tam giác cân tạo bởi đường chéo để suy ra.'},
{id:'th_square',concept:'square',name:'Tính chất tổng hợp hình vuông',statement:'Hình vuông có các tính chất của hình chữ nhật và hình thoi.',conditions:'ABCD là hình vuông.',conclusion:'Bốn cạnh bằng nhau, bốn góc vuông; hai đường chéo bằng nhau, vuông góc và cắt nhau tại trung điểm mỗi đường.',proof:'Hình vuông đồng thời là hình chữ nhật và hình thoi.'}
] AS x
MERGE (t:Theorem {id:x.id}) SET t.name=x.name,t.statement=x.statement,t.conditions=x.conditions,t.conclusion=x.conclusion,t.proof=x.proof
WITH t,x MATCH (c:Concept {id:x.concept}) MERGE (c)-[:HAS_THEOREM]->(t);

UNWIND [
{id:'f_quad_angle',concept:'quad',name:'Tổng góc tứ giác',expression:'A + B + C + D = 360°',variables:['A, B, C, D: số đo bốn góc trong'],conditions:'Tứ giác lồi.'},
{id:'f_trap_area',concept:'trapezoid',name:'Diện tích hình thang',expression:'S = (a + b) × h / 2',variables:['a, b: độ dài hai đáy','h: chiều cao'],conditions:'Các đại lượng dùng cùng đơn vị độ dài.'},
{id:'f_iso_area',concept:'isosceles_trapezoid',name:'Diện tích hình thang cân',expression:'S = (a + b) × h / 2',variables:['a, b: hai đáy','h: chiều cao'],conditions:'Dùng công thức diện tích hình thang.'},
{id:'f_right_area',concept:'right_trapezoid',name:'Diện tích hình thang vuông',expression:'S = (a + b) × h / 2',variables:['a, b: hai đáy','h: chiều cao'],conditions:'Cạnh bên vuông góc với đáy là chiều cao.'},
{id:'f_para_area',concept:'parallelogram',name:'Diện tích hình bình hành',expression:'S = a × h',variables:['a: độ dài đáy','h: chiều cao tương ứng'],conditions:'h là chiều cao ứng với đáy a.'},
{id:'f_para_perimeter',concept:'parallelogram',name:'Chu vi hình bình hành',expression:'P = 2(a + b)',variables:['a, b: hai cạnh kề'],conditions:'Cộng độ dài bốn cạnh.'},
{id:'f_rect_area',concept:'rectangle',name:'Diện tích hình chữ nhật',expression:'S = a × b',variables:['a, b: hai cạnh kề'],conditions:'Hai cạnh cùng đơn vị.'},
{id:'f_rect_perimeter',concept:'rectangle',name:'Chu vi hình chữ nhật',expression:'P = 2(a + b)',variables:['a, b: chiều dài và chiều rộng'],conditions:'Hai cạnh kề.'},
{id:'f_rhombus_area',concept:'rhombus',name:'Diện tích hình thoi theo đường chéo',expression:'S = d₁ × d₂ / 2',variables:['d₁, d₂: độ dài hai đường chéo'],conditions:'Hai đường chéo cùng đơn vị.'},
{id:'f_rhombus_perimeter',concept:'rhombus',name:'Chu vi hình thoi',expression:'P = 4a',variables:['a: độ dài cạnh'],conditions:'Bốn cạnh bằng nhau.'},
{id:'f_square_area',concept:'square',name:'Diện tích hình vuông',expression:'S = a²',variables:['a: độ dài cạnh'],conditions:'a là độ dài cạnh hình vuông.'},
{id:'f_square_perimeter',concept:'square',name:'Chu vi hình vuông',expression:'P = 4a',variables:['a: độ dài cạnh'],conditions:'Bốn cạnh bằng nhau.'}
] AS x
MERGE (f:Formula {id:x.id}) SET f.name=x.name,f.expression=x.expression,f.variables=x.variables,f.conditions=x.conditions
WITH f,x MATCH (c:Concept {id:x.concept}) MERGE (c)-[:HAS_FORMULA]->(f);

UNWIND [
{id:'tip_quad',concept:'quad',content:'Kẻ một đường chéo để chia tứ giác thành hai tam giác khi cần chứng minh tổng góc.'},
{id:'tip_trap',concept:'trapezoid',content:'Khi nhận diện hình thang, hãy xác định cặp cạnh đối song song và chú ý chiều cao vuông góc với hai đáy.'},
{id:'tip_iso',concept:'isosceles_trapezoid',content:'Nhớ ba tính chất thường dùng: hai cạnh bên bằng nhau, góc kề mỗi đáy bằng nhau, hai đường chéo bằng nhau.'},
{id:'tip_right',concept:'right_trapezoid',content:'Ở hình thang vuông, cạnh bên vuông góc với hai đáy chính là chiều cao.'},
{id:'tip_para',concept:'parallelogram',content:'Khi chứng minh hình bình hành, hãy kiểm tra hai cặp cạnh đối song song, hai cặp cạnh đối bằng nhau hoặc hai đường chéo cắt nhau tại trung điểm.'},
{id:'tip_rect',concept:'rectangle',content:'Hình chữ nhật có đầy đủ tính chất hình bình hành và thêm tính chất hai đường chéo bằng nhau.'},
{id:'tip_rhombus',concept:'rhombus',content:'Trong hình thoi, hai đường chéo vuông góc và phân giác các góc; hình thoi cũng là hình bình hành.'},
{id:'tip_square',concept:'square',content:'Hình vuông vừa là hình chữ nhật vừa là hình thoi, nên có thể kết hợp tính chất của cả hai hình.'}
] AS x
MERGE (t:Tip {id:x.id}) SET t.content=x.content,t.author='GeoKnowledge',t.status='published'
WITH t,x MATCH (c:Concept {id:x.concept}) MERGE (c)-[:HAS_TIP]->(t);

UNWIND [
{id:'ex_quad_01',concept:'quad',question:'Tổng số đo bốn góc trong một tứ giác lồi là bao nhiêu?',exercise_type:'MCQ',difficulty:'Dễ',options:['180°','270°','360°','540°'],correct_answer:'360°',solution:'Tổng bốn góc bằng 360°.',solution_steps:['Kẻ một đường chéo chia tứ giác thành hai tam giác.','Tổng các góc bằng 180° + 180° = 360°.']},
{id:'ex_quad_02',concept:'quad',question:'Ba góc của tứ giác lần lượt là 80°, 95° và 100°. Góc còn lại bằng bao nhiêu?',exercise_type:'FREE_RESPONSE',difficulty:'Trung bình',options:[],correct_answer:'85°',solution:'Góc còn lại = 360° − (80° + 95° + 100°) = 85°.',solution_steps:['Tính tổng ba góc: 80° + 95° + 100° = 275°.','Lấy 360° − 275° = 85°.']},
{id:'ex_trap_01',concept:'trapezoid',question:'Hình thang có hai đáy 6 cm và 10 cm, chiều cao 4 cm. Diện tích bằng bao nhiêu?',exercise_type:'MCQ',difficulty:'Dễ',options:['16 cm²','24 cm²','32 cm²','40 cm²'],correct_answer:'32 cm²',solution:'S = (6 + 10) × 4 / 2 = 32 cm².',solution_steps:['Cộng hai đáy: 6 + 10 = 16.','Tính diện tích: 16 × 4 / 2 = 32 cm².']},
{id:'ex_trap_02',concept:'trapezoid',question:'Hai góc kề một cạnh bên của hình thang lần lượt là  x và 110°. Tìm x.',exercise_type:'FREE_RESPONSE',difficulty:'Trung bình',options:[],correct_answer:'70°',solution:'x + 110° = 180°, suy ra x = 70°.',solution_steps:['Hai đáy song song nên hai góc trong cùng phía bù nhau.','x = 180° − 110° = 70°.']},
{id:'ex_iso_01',concept:'isosceles_trapezoid',question:'Hình thang cân có góc A kề đáy AB bằng 65°. Góc B bằng bao nhiêu?',exercise_type:'MCQ',difficulty:'Dễ',options:['25°','65°','115°','130°'],correct_answer:'65°',solution:'Hai góc kề cùng đáy của hình thang cân bằng nhau.',solution_steps:['ABCD là hình thang cân.','∠A = ∠B nên ∠B = 65°.']},
{id:'ex_iso_02',concept:'isosceles_trapezoid',question:'Hình thang cân có hai đáy 8 cm và 14 cm, chiều cao 5 cm. Tính diện tích.',exercise_type:'FREE_RESPONSE',difficulty:'Trung bình',options:[],correct_answer:'55 cm²',solution:'S = (8 + 14) × 5 / 2 = 55 cm².',solution_steps:['Áp dụng công thức diện tích hình thang.','Thay số: (8 + 14) × 5 / 2 = 55 cm².']},
{id:'ex_right_01',concept:'right_trapezoid',question:'Hình thang vuông có hai đáy 5 cm và 9 cm, chiều cao 3 cm. Diện tích là bao nhiêu?',exercise_type:'MCQ',difficulty:'Dễ',options:['14 cm²','21 cm²','27 cm²','42 cm²'],correct_answer:'21 cm²',solution:'S = (5 + 9) × 3 / 2 = 21 cm².',solution_steps:['Dùng công thức diện tích hình thang.','Thay số được 21 cm².']},
{id:'ex_right_02',concept:'right_trapezoid',question:'Một góc của hình thang vuông bằng 90°. Góc vuông còn lại kề cùng cạnh bên với góc đó bằng bao nhiêu?',exercise_type:'FREE_RESPONSE',difficulty:'Trung bình',options:[],correct_answer:'90°',solution:'Hai góc kề cạnh bên bù nhau nên góc còn lại bằng 180° − 90° = 90°.',solution_steps:['Hai đáy song song.','Hai góc trong cùng phía bù nhau.']},
{id:'ex_para_01',concept:'parallelogram',question:'Hình bình hành có đáy 12 cm và chiều cao tương ứng 4 cm. Diện tích là bao nhiêu?',exercise_type:'MCQ',difficulty:'Dễ',options:['16 cm²','24 cm²','48 cm²','96 cm²'],correct_answer:'48 cm²',solution:'S = a × h = 12 × 4 = 48 cm².',solution_steps:['Dùng công thức S = a × h.','Thay số và tính được 48 cm².']},
{id:'ex_para_02',concept:'parallelogram',question:'Một hình bình hành có hai cạnh kề dài 7 cm và 5 cm. Chu vi là bao nhiêu?',exercise_type:'FREE_RESPONSE',difficulty:'Trung bình',options:[],correct_answer:'24 cm',solution:'P = 2 × (7 + 5) = 24 cm.',solution_steps:['Các cạnh đối bằng nhau.','P = 2 × (7 + 5) = 24 cm.']},
{id:'ex_rect_01',concept:'rectangle',question:'Hình chữ nhật có chiều dài 8 cm và chiều rộng 5 cm. Diện tích bằng bao nhiêu?',exercise_type:'MCQ',difficulty:'Dễ',options:['13 cm²','26 cm²','40 cm²','80 cm²'],correct_answer:'40 cm²',solution:'S = 8 × 5 = 40 cm².',solution_steps:['Dùng S = a × b.','Thay số: 8 × 5 = 40 cm².']},
{id:'ex_rect_02',concept:'rectangle',question:'Hình chữ nhật có hai cạnh kề 9 cm và 4 cm. Chu vi bằng bao nhiêu?',exercise_type:'MCQ',difficulty:'Dễ',options:['13 cm','26 cm','36 cm','18 cm'],correct_answer:'26 cm',solution:'P = 2 × (9 + 4) = 26 cm.',solution_steps:['Cộng hai cạnh kề được 13 cm.','Nhân đôi được 26 cm.']},
{id:'ex_rhombus_01',concept:'rhombus',question:'Hình thoi có cạnh dài 6 cm. Chu vi bằng bao nhiêu?',exercise_type:'MCQ',difficulty:'Dễ',options:['12 cm','18 cm','24 cm','36 cm'],correct_answer:'24 cm',solution:'P = 4 × 6 = 24 cm.',solution_steps:['Hình thoi có bốn cạnh bằng nhau.','P = 4 × 6 = 24 cm.']},
{id:'ex_rhombus_02',concept:'rhombus',question:'Hình thoi có hai đường chéo dài 6 cm và 8 cm. Diện tích là bao nhiêu?',exercise_type:'FREE_RESPONSE',difficulty:'Trung bình',options:[],correct_answer:'24 cm²',solution:'S = 6 × 8 / 2 = 24 cm².',solution_steps:['Dùng công thức diện tích theo hai đường chéo.','Thay số: 6 × 8 / 2 = 24 cm².']},
{id:'ex_square_01',concept:'square',question:'Hình vuông có cạnh 7 cm. Diện tích bằng bao nhiêu?',exercise_type:'MCQ',difficulty:'Dễ',options:['14 cm²','28 cm²','49 cm²','21 cm²'],correct_answer:'49 cm²',solution:'S = 7² = 49 cm².',solution_steps:['Dùng công thức S = a².','Thay a = 7 cm được 49 cm².']},
{id:'ex_square_02',concept:'square',question:'Một hình chữ nhật có hai cạnh kề bằng nhau. Hình đó là hình gì?',exercise_type:'MCQ',difficulty:'Trung bình',options:['Hình thang cân','Hình bình hành bất kỳ','Hình vuông','Hình thang vuông'],correct_answer:'Hình vuông',solution:'Hình chữ nhật có hai cạnh kề bằng nhau là hình vuông.',solution_steps:['Hình chữ nhật có bốn góc vuông.','Hai cạnh kề bằng nhau và các cạnh đối bằng nhau nên bốn cạnh bằng nhau.']}
] AS x
MERGE (e:Exercise {id:x.id})
SET e.question=x.question,e.exercise_type=x.exercise_type,e.difficulty=x.difficulty,e.options=x.options,
    e.correct_answer=x.correct_answer,e.solution=x.solution,e.solution_steps=x.solution_steps,e.status='published'
WITH e,x MATCH (c:Concept {id:x.concept})
MERGE (c)-[:HAS_EXERCISE]->(e) MERGE (e)-[:APPLIES_TO]->(c);

// Quan hệ học trước: hình nâng cao yêu cầu hiểu hình tổng quát.
UNWIND [
['trapezoid','quad'],['isosceles_trapezoid','trapezoid'],['right_trapezoid','trapezoid'],
['parallelogram','trapezoid'],['rectangle','parallelogram'],['rhombus','parallelogram'],['square','rectangle'],['square','rhombus']
] AS pair
MATCH (advanced:Concept {id:pair[0]}),(pre:Concept {id:pair[1]})
MERGE (advanced)-[:REQUIRES_PREREQUISITE]->(pre);
