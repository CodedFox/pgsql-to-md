# To run, install Ruby and use the following command: ruby -w db-table-extract.rb outreach-v3.sql
# Extracted .md file will be in the same directory as this script.

class Table

    def initialize(name)
        @name = name
        @attributes = {}
        @aCounter = 0
        @constraints = {}
        @cCounter = 0

    end

    def primaryKey(pk)
        @pk = pk
    end

    def name
        return @name
    end

    def pk
        return @pk
    end

    def addAttribute(attribute)
        @attributes[@aCounter] = attribute
        @aCounter = @aCounter + 1
    end

    def attributes
        return @attributes
    end

    def addConstraint(constraint)
        @constraints[@cCounter] = constraint
        @cCounter = @cCounter + 1
    end

    def constraints
        return @constraints
    end
end

class Attribute
    def initialize()
        @name = ""
        @type = ""
        @isNullable = true
        @isUnique = false
        @defaultValue = ""
        @fk = ""
    end

    def addName(name)
        @name = name

    end

    def name
        return @name
    end

    def addType(type)
        @type = type
    end
  
    def type
        return @type
    end

    def addIsNullable(isNullable)
        @isNullable = isNullable
    end

    def isNullable
        return @isNullable
    end

    def addIsUnique(isUnique)
        @isUnique = isUnique
    end

    def isUnique
        return @isUnique            
    end

    def addDefaultValue(defaultValue)
        @defaultValue = defaultValue
    end

    def defaultValue
        return @defaultValue
    end

    def foreignKey(fk)
        @fk = fk
    end

    def fk
        return @fk

    end
end

class Constraint
    def initialize
        @values = {}
        @counter = 0    
    end

    def addValue(value)
        @values[@counter] = value
        @counter = @counter + 1

    end

    def values
        return @values
    end
end

def parse_data
    file_name = ARGV[0]
    counter = 0
    tables = {}

    File.open(file_name).each do |line|

        words = line.split()

        unless words[0].nil? 
            unless words[0].eql? "--"

                if words[0].eql? "CREATE"
                    tables[counter] = Table.new words[2].chomp('(')

                elsif words[0].eql? "PRIMARY"
                    tables[counter].primaryKey words[2].chomp(')').chomp('),')[1..-1]
                
                elsif words[0].eql? "UNIQUE"
                    constraint = Constraint.new

                    words.each do |word|
                        unless word.eql? "UNIQUE"
                            if word[0].eql? "("
                                constraint.addValue word.chomp(')').chomp('),').chomp(',')[1..-1]
                            else
                                constraint.addValue word.chomp(')').chomp('),').chomp(',')
                            end
                        end
                    end

                    tables[counter].addConstraint constraint
                    
                elsif !line.include?("DROP") && !words[0].eql?(");")
                    attribute = Attribute.new
                    attribute.addName words[0]
                    attribute.addType words[1].chomp(',')
                    attribute.addIsNullable (!line.include?("NOT NULL") && !line.include?("SERIAL"))
                    attribute.addIsUnique line.include? "UNIQUE"

                    if line.include? "DEFAULT"
                        index = words.index("DEFAULT") + 1
                        attribute.addDefaultValue words[index].chomp(',')
                    end

                    if line.include? "REFERENCES"
                        index = words.index("REFERENCES") + 1
                        attribute.foreignKey words[index].chomp(',')
                    end

                    tables[counter].addAttribute attribute
                end

                if line.include? ");"
                    counter = counter + 1
                end
            end
        end
    end

    return tables
end

# call function
tables = parse_data

sortedTables = tables.sort_by {|_key, values| values.name}

file = File.open("Database.md", "w")

sortedTables.each do |key, table|
    file.puts("#### " + table.name)
    file.puts("|Attribute|Type|Nullable?|Unique?|Default|Foreign Key|")
    file.puts("|---|:---:|:---:|:---:|:---:|---|")

    table.attributes.each do |tableKey, attribute|
        nullable = ""
        unique = ""

        if attribute.isNullable == true
            nullable = "✓"
        end

        if attribute.isUnique == true
            unique = "✓"
        end

        file.puts("|" + attribute.name + "|" + attribute.type + "|" + nullable + "|" + unique + "|" + attribute.defaultValue + "|" + attribute.fk + "|")
    end

    file.puts
    file.puts("|Constraint|Attribute|")
    file.puts("|---|---|")
    file.puts("|Primary Key|" + table.pk + "|")

    table.constraints.each do |attributeKey, constraint|

        aValues = Array.new(constraint.values.length)

        constraint.values.each do |constraintKey, value|
            aValues[constraintKey] = value
        end

        file.puts("|Unique|" + aValues.join(", ") + "|")
    end

    file.puts
end

file.close
