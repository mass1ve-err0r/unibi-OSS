using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;


namespace RA_QuinMcCluskey_CSharp
{
    class Program
    {
        // globals
        static List<(string occupation, List<int> decimalIdx, bool used)> Occupations = new List<(string, List<int>, bool)>();
        static List<(string occupation, List<int> decimalIdx, bool used)> ps = new List<(string, List<int>, bool)>();
        static uint x_vars = 0, x_star_vars = 0, occ_amount = 0, occ_star_amount = 0, iter = x_vars;
        static string QuitMessage = "Press any key to contiue";
        static string loc = Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location);

        // Entrypoint
        static void Main(string[] args) {
            Console.Title = "RA19: Quine-McCluskey - C# Variant by Mirza Saadat Baig, WiSe19/20 @UniBielefeld";
            Console.WriteLine("Following Fields are Present:");
            // Check given input, ditch global path checking since we on windows & this is a demo
            // Info on ConsoleColor has been graciously provided by dotNetPerls
            // Link: http://dotnetperls.com/console-color
            if (args.Length != 2) {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine("Missing File Arguments! " +
                                  "Usage:\n" +
                                  "<executableName> <File1>.txt <File2>.txt\n" +
                                  "Example:\nqmc QMC_OneOccupation.txt QMC_StarOccupation.txt\n" +
                                  "\n(!) Files are scanned IN THE FOLDER where you have lauched the program");
                Console.WriteLine(QuitMessage);
                Console.ResetColor();
                Console.ReadKey();
                Environment.Exit(-100);
            }
            else if (args.Length == 2 && File.Exists(loc + "\\" + args[0]) && File.Exists(loc + "\\" + args[1])) {
                readOccupations(args[0], 0);
                readOccupations(args[1], 1);
                RecursiveComparator(Occupations);
                Console.ReadKey();
            }
            else {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.Error.WriteLine("File(s) do NOT exist in current directory!");
                Console.WriteLine(QuitMessage);
                Console.ResetColor();
                Console.ReadKey();
                Environment.Exit(-200);
            }
        }

        /**
         * RecursiveComparator - A recursive approach to produce primes through QMC
         * 
         * 1.   The function takes in (INITIALLY) a list, which has been crafted by
         *      reading in the occupations from both files. (1's and *'s)
         * 2.   The function then compares the first element against the whole list.
         * 3.   During evaluation, it then builds the difference in chars from
         *      elem1 & elem2. If this very diff equals 1, it is then stored in
         *      internal List (of the same type) & marked as used.
         *      (List of a 3-Tuple; 3-Tuple of Type string, List<int>, bool)
         *      (=> Tuple[1]: Occupations, Tuple[2]: DecimalVal/Idx, Tuple[3]: Used status)
         * 4.   If diff deos not equal 1, the occupation is then noted as prime
         *      due to it NOT merging with any other occupation & added to a
         *      seperate prime list.
         * 5.   if the internal list consists of at least one (1) item, the 
         *      function is recusively called again with the internal list
         *      as new parameter/ new list to work with.
         * 6.   if the later constructed internal list is empty, it means we now
         *      only have primes left & therefore print out our prime table!
         * 420. I lost my soul while working on this lmao
        */
        static void RecursiveComparator(List<(string occupation, List<int> decimalIdx, bool used)> table) {
            char[] w1, w2;
            List<(string occupation, List<int> decimalIdx, bool used)> local_occ = new List<(string, List<int>, bool)>();
            List<int> ret_idxs = new List<int>();
            StringBuilder sb = new StringBuilder();
            for (int i = 0; i < table.Count; i++) {
                w1 = table[i].occupation.ToCharArray();
                for (int j = i + 1; j < table.Count; j++) {
                    int diff = 0;
                    w2 = table[j].occupation.ToCharArray();
                    for (int m = 0; m < w2.Length; m++) {
                        if (w1[m].Equals(w2[m])) {
                            sb.Append(w1[m]);
                        }
                        else {
                            sb.Append('-');
                            diff++;
                        }
                    }
                    if (diff == 1) {
                        ret_idxs.AddRange(table[i].decimalIdx.AsEnumerable());
                        ret_idxs.AddRange(table[j].decimalIdx.AsEnumerable());
                        local_occ.Add((sb.ToString(), ret_idxs.ToList(), false));
                        var a1 = table[i].occupation;
                        var b1 = table[i].decimalIdx;
                        var a2 = table[j].occupation;
                        var b2 = table[j].decimalIdx;
                        table[i] = (a1, b1, true);
                        table[j] = (a2, b2, true);
                    }
                    // clean-up!
                    sb.Clear();
                    ret_idxs.Clear();
                }
                if (table[i].used == false) {
                    ret_idxs.AddRange(table[i].decimalIdx.AsEnumerable());
                    ps.Add((table[i].occupation, ret_idxs.ToList(), false));
                    ret_idxs.Clear();
                }
            }
            if (local_occ.Count > 0) {
                /*      DEBUG PURPOSES ONLY
                Console.WriteLine("Round Results:");
                foreach (var item in local_occ) {
                    Console.WriteLine(item.occupation + " " + String.Join(",", item.decimalIdx));
                }
                */
                RecursiveComparator(local_occ);
            }
            else {
                Console.ForegroundColor = ConsoleColor.Green;
                Console.WriteLine("\nFinal Primes:");
                foreach (var item in ps) {
                    Console.WriteLine(item.occupation + " " + String.Join(",", item.decimalIdx));
                }
                Console.ResetColor();
            }
        }

        /**
         * readOccupations - A custom FileReader
         * Due to the Task's Layout (RA19), the file structure is as follows:
         * (Row1) <# of vars> <# of occupations in total>
         * (Row2-RowN) <Occupation>
         * For Example see the attached files (Occupations from RA18)
        */
        static void readOccupations(string path, int type) {
            string infos, line;
            StreamReader streamReader = new StreamReader(path);
            // read out vars & co.
            infos = streamReader.ReadLine();
            if (type == 0) {
                x_vars = uint.Parse(infos.Substring(0, 1));
                occ_amount = uint.Parse(infos.Substring(2, 1));
            }
            else {
                x_star_vars = uint.Parse(infos.Substring(0, 1));
                occ_star_amount = uint.Parse(infos.Substring(2, 1));
            }
            // populate array with content
            while ((line = streamReader.ReadLine()) != null) {
                line = Regex.Replace(line, @"\s+", String.Empty);
                Console.WriteLine(line);
                Occupations.Add((line, new List<int> { Convert.ToInt32(line, 2) }, false));
            }
        }
        // fin.
    }
}
