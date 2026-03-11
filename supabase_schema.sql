-- Create questions table
CREATE TABLE questions (
    id bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    category text NOT NULL,
    question_text text NOT NULL,
    a text NOT NULL,
    b text NOT NULL,
    c text NOT NULL,
    d text NOT NULL,
    correct_option text NOT NULL CHECK (correct_option IN ('a', 'b', 'c', 'd'))
);

-- Create rooms table
CREATE TABLE rooms (
    room_code text PRIMARY KEY,
    player1 text,
    player2 text,
    p1_score int DEFAULT 0,
    p2_score int DEFAULT 0,
    current_q_index int DEFAULT 0,
    status text DEFAULT 'waiting' CHECK (status IN ('waiting', 'playing', 'finished')),
    category text
);

-- Insert sample data (15 questions)
INSERT INTO questions (category, question_text, a, b, c, d, correct_option) VALUES
-- Islamic (5 questions)
('Islamic', 'Who was the first muezzin in Islam?', 'Bilal ibn Rabah', 'Abu Bakr', 'Umar ibn Al-Khattab', 'Ali ibn Abi Talib', 'a'),
('Islamic', 'Which Surah is known as the Heart of the Quran?', 'Surah Al-Fatiha', 'Surah Yasin', 'Surah Al-Baqarah', 'Surah Al-Kahf', 'b'),
('Islamic', 'In which year did the Hijrah take place?', '610 AD', '622 AD', '632 AD', '600 AD', 'b'),
('Islamic', 'How many times is the Prophet Muhammad (PBUH) mentioned by name in the Quran?', '4', '25', '114', '99', 'a'),
('Islamic', 'What is the name of the cave where the Prophet Muhammad (PBUH) received the first revelation?', 'Cave of Thawr', 'Cave of Hira', 'Cave of Uhud', 'Cave of Safa', 'b'),

-- History (5 questions)
('History', 'Who built the Great Wall of China?', 'Qin Shi Huang', 'Genghis Khan', 'Kublai Khan', 'Sun Tzu', 'a'),
('History', 'In which year did World War 2 end?', '1918', '1939', '1941', '1945', 'd'),
('History', 'Who was the first President of the United States?', 'Thomas Jefferson', 'George Washington', 'Abraham Lincoln', 'John Adams', 'b'),
('History', 'The Titanic sank in which year?', '1910', '1912', '1914', '1920', 'b'),
('History', 'Which ancient civilization built the Pyramids of Giza?', 'Romans', 'Greeks', 'Egyptians', 'Mayans', 'c'),

-- Science (5 questions)
('Science', 'What is the chemical symbol for Gold?', 'Au', 'Ag', 'Fe', 'Cu', 'a'),
('Science', 'Which planet is known as the Red Planet?', 'Venus', 'Mars', 'Jupiter', 'Saturn', 'b'),
('Science', 'What is the hardest natural substance on Earth?', 'Gold', 'Iron', 'Diamond', 'Platinum', 'c'),
('Science', 'How many bones are in the adult human body?', '206', '208', '210', '215', 'a'),
('Science', 'What gas do plants absorb from the atmosphere?', 'Oxygen', 'Nitrogen', 'Carbon Dioxide', 'Hydrogen', 'c');
