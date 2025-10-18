// =============================================================================
// DeduKt Language Grammar file
// =============================================================================
// The following file is the main grammar definition for DeduKt language.
// This is being used to create the parser and lexer.
parser grammar DeduktParser;

options {
    tokenVocab=DeduktLexer;
}
// =============================================================================
// SOURCE CODE STRUCTURE
// =============================================================================

/**
 * Entry point for DeduKt source files
 * Structure: [header] [body] | empty file
 *
 * Examples:
 *   package com.example; fun main() { ... }
 *   // Empty file is valid
 */
deduktSourceCode
    : header? body? | EOF
    ;

// =============================================================================
// HEADER SECTION - Package and Import Declarations
// =============================================================================

/**
 * File header containing package declaration and optional imports
 * Must appear at the beginning of file before any implementations
 *
 * Structure: package declaration + optional imports
 * Example: package math.algebra; import std.collections.*; import io.files;
 */
header
    : packageDeclaration importList?
    ;

/**
 * Package declaration - required for all DeduKt files
 * Establishes namespace and enables module system integration
 * Supports hierarchical package structure with dot notation
 *
 * Syntax: package <identifier>.<identifier>...
 * Example: package mathematics.linear_algebra.vectors
 */
packageDeclaration
    : Package SpaceOrTab* packageIdentifier NL*
    ;

/**
 * Hierarchical package identifier using dot notation
 * Allows nested package structures for better organization
 *
 * Examples: std, math.algebra, com.example.utils
 */

packageIdentifier
    : packageIdentifierNode (Dot packageIdentifierNode )*
    ;

packageIdentifierNode
    : SimpleIdentifier
    | Package | Import | Type | Where | If | Else | Case | Default | When | Gaurd | For | While | Do | Break | BreakAt
    | Continue | ContinueAt | Return | ReturnAt | Jump | Val | Var | Const | Throw | Catch | Finally | Try | Assert
    | Debug | Context | Notation | Axiom | Fun | Operator | Structure | Theory | Rule | Abstract | True | False;


/**
 * Collection of import statements
 * Brings external symbols into current namespace
 * Supports both specific imports and wildcard imports
 */
importList
    : importStatement+
    ;

/**
 * Individual import statement
 * Can import specific package or use wildcard (*) for all symbols
 *
 * Syntax: import <package>[.*]
 * Examples:
 *   import std.collections
 *   import math.algebra.*
 */
importStatement
    : Import SpaceOrTab* packageIdentifier (Dot Star)? NL*
    ;

// =============================================================================
// BODY SECTION - Implementation Statements
// =============================================================================

/**
 * Main body containing all declarations and implementations
 * Consists of zero or more statements that define the program logic
 */
body
    : statement+
    ;

/**
 * Individual statement in DeduKt source code
 * Currently supports declarations only (applications/evaluations to be added)
 * Each statement defines a mathematical or computational construct
 */
statement
    : declaration
    | application
    ;
// =============================================================================
// APPLICATION RULES - Expressions, Statements and Control Flow
// =============================================================================

/**
* Application rule - top-level evaluable statements in DeduKt
* Represents any statement that DeduKt can theoretically evaluate
* Includes pure evaluations, transformable expressions, control flow,
* loops, variable assignments, and other executable constructs
*
* Syntax: <expression> | <statement> | <control_flow>
* Examples:
*   x + y * z
*   result = calculate{a, b}
*   if condition then action
*/
application
   : expression SemiColon?
   | conditional
   | loop
   | jump
   | variableOperation
   | errorHandling
//   | ioOperation
//   | memoryOperation
   | debugOperation
   ;
/**
* Main expression rule - entry point for all expression parsing
* Delegates to chain expressions which have the highest precedence
* Forms the root of the expression hierarchy
*
* Syntax: <chainExpression>
*/

/**
* Chain expressions - hierarchical chaining with proper tree structure
* Each chain operation creates a parent-child relationship in the AST
* Left-recursive rule that builds the tree incrementally
*
* Syntax: <chainExpression> <chainOp> | <primaryExpression>
* Tree structure: first.second.third creates first -> second -> third hierarchy
*/
expression
   : expression primaryExpression // Juxtaposition (function application)
   | primaryExpression                 // Base case: single primary expression
   ;

/**
* Chain operators - operators for chaining expressions
* Each operator type creates a specific parent-child relationship
* The left-recursive structure ensures proper tree building
*
* Syntax: .<identifier>{<args>} | .{<expressions>} | .<identifier>
* Examples:
*   .method{arg1, arg2}    // Method call becomes child of previous expression
*   .{x -> x + 1}          // Headless function application as child
*   .property              // Property access as child
*/
chainOperator
   : (identifier | literal) Dot functionCall             // .identifier{args}
   | (identifier | literal) Dot headlessFunction         // .{expressions}
   | (identifier | literal) Dot identifier               // .property
   ;

/**
* Primary expressions - atomic expression units
* Base cases for the expression grammar hierarchy
* Removed multipleIdentifiers to avoid confusion with juxtaposition
*
* Syntax: <identifier> | {<expressions>} | <identifier>{<args>} | (<expression>)
* Examples:
*   variable               // Single identifier
*   {x -> x * 2}          // Headless function
*   calculate{a, b, c}    // Function call
*   (x + y) * z           // Parenthesized expression
*/
primaryExpression
   : multipleIdentifiers                   // Case 1: single identifier
   | headlessFunction            // Case 3: headless function
   | functionCall                // Case 4: function call
   | LParen expression RParen    // Case 5: compound expression (parentheses)
   | lateAssignment              // Case 6: late assignment
   ;


/**
* Function call - identifier followed by argument list in curly braces
* Standard function invocation syntax with comma-separated arguments
* Arguments are optional - empty braces represent no-argument calls
*
* Syntax: <identifier>{[<arg1>, <arg2>, ...]}
* Examples:
*   calculate{x, y, z}     // Function with multiple arguments
*   getValue{}             // Function with no arguments
*   process{data.field}    // Function with complex argument
*/
functionCall
   : identifier LBrace argumentList? RBrace
   ;

/**
* Argument list - comma-separated sequence of expressions
* Used in function calls and other parameter-passing contexts
* Each argument is a full expression allowing complex nested structures
*
* Syntax: <expression> [, <expression>]*
* Examples:
*   x, y, z                // Simple variables
*   a + b, func{c}, d.prop // Mixed expression types
*/
argumentList
   : expression (Comma expression)*
   ;
multipleIdentifiers
    : atomExpression+
    ;
atomExpression
    : identifier    | chainOperator  | literal
    ;
// =============================================================================
// CONDITIONAL STATEMENTS - Branching Control Flow
// =============================================================================

/**
 * Conditional statement - all forms of branching control flow
 * Supports if/else chains, pattern matching, and multi-way branching
 *
 * Syntax: <ifStatement> | <caseStatement> | <whenStatement> | <guardStatement>
 */
conditional
    : ifStatement
//    | caseStatement
    | whenStatement
    | guardStatement
    | ternaryExpression
    ;

/**
 * If statement - traditional conditional branching
 * Supports single condition with optional else clause and elif chains
 *
 * Syntax: if <condition> then <body> [elif <condition> then <body>]* [else <body>]
 * Examples:
 *   if x > 0 then positive
 *   if x > 0 then positive else negative
 *   if x > 0 then positive elif x < 0 then negative else zero
 */
ifStatement
    : mainConditional elseIfConditionals* elseStatement
    ;

mainConditional
    : If expression (Arrow  LBrace statement+ RBrace)
    ;
elseIfConditionals
    : (Else If expression (Arrow  LBrace statement+ RBrace))
    ;
elseStatement
    : (Else (Arrow  LBrace statement+ RBrace))?
    ;
/**
 * Case statement - pattern matching and multi-way branching
 * Supports pattern matching on values, types, and structure
 *
 * Syntax: case <expression> of <pattern> -> <body> [| <pattern> -> <body>]* [| _ -> <body>]
 * Examples:
 *   case value of 1 -> first | 2 -> second | _ -> other
 *   case shape of Circle{r} -> area{r} | Rectangle{w, h} -> w * h
 */
caseStatement
    : Case expression Arrow (expression | returnable)
    ;
defaultStatement
    : Default (expression | returnable)
    ;
caseStatements
    : caseStatement+ defaultStatement
    ;
/**
 * When statement - condition-based multi-branch selection
 * Similar to case but based on boolean conditions rather than pattern matching
 *
 * Syntax: when <condition> -> <body> [| <condition> -> <body>]* [| else -> <body>]
 * Examples:
 *   when x > 0 -> positive | x < 0 -> negative | else -> zero
 *   when hasPermission -> allow | isGuest -> restricted | else -> deny
 */
whenStatement
    : When proposedExpression LBrace caseStatements RBrace
    ;
proposedExpression
    : expression
    ;

/**
 * Guard statement - condition-based early return/exit
 * Supports early termination based on conditions
 *
 * Syntax: guard <condition> else <action>
 * Examples:
 *   guard hasAccess else throw unauthorized
 */
guardStatement
    : Gaurd expression (Else Throw expression)?
    ;

/**
 * Ternary expression - inline conditional expression
 * Compact conditional for simple value selection
 *
 * Syntax: <condition> ? <trueValue> : <falseValue>
 * Examples:
 *   x > 0 ? positive : negative
 *   hasValue ? getValue{} : defaultValue
 */
ternaryExpression
    : expression QuestionMark expression Colon expression
    ;
// =============================================================================
// LOOP STATEMENTS - Iterative Control Flow
// =============================================================================

/**
 * Loop statement - all forms of iterative execution
 * Supports counted loops, conditional loops, and iterator-based loops
 *
 * Syntax: <forLoop> | <whileLoop> | <doWhileLoop> | <foreachLoop>
 */
loop
    : forLoop
    | whileLoop
    | doWhileLoop
    ;
loopBody
    : (Arrow expression | LBrace statement+ RBrace)
    ;
/**
 * For loop - counted iteration with initialization, condition, and increment
 * Traditional C-style for loop with explicit control variables
 *
 * Syntax: for <init>; <condition>; <increment> do <body>
 * Examples:
 *   for i = 0; i < 10; i += 1 do process{i}
 *   for x = start; x <= end; x *= 2 do calculate{x}
 */
forLoop
    : For expression loopBody
    ;

/**
 * While loop - condition-based pre-test iteration
 * Executes body while condition remains true
 *
 * Syntax: while <condition> do <body>
 * Examples:
 *   while hasMore{} do processNext{}
 *   while x > 0 do x = x / 2
 */
whileLoop
    : While expression loopBody
    ;

/**
 * Do-while loop - condition-based post-test iteration
 * Executes body at least once, then continues while condition is true
 *
 * Syntax: do <body> while <condition>
 * Examples:
 *   do getUserInput{} while isInvalid{input}
 *   do processData{} while hasMoreData{}
 */
doWhileLoop
    : Do loopBody While expression
    ;



// =============================================================================
// JUMP STATEMENTS - Control Flow Interruption
// =============================================================================

/**
 * Jump statement - control flow interruption and redirection
 * Supports various forms of non-local control transfer
 *
 * Syntax: <breakStatement> | <continueStatement> | <returnStatement> | <gotoStatement>
 */
jump
    : breakStatement
    | continueStatement
    | returnStatement
    | gotoStatement
    ;

/**
 * Break statement - exit from current loop or block
 * Terminates the nearest enclosing loop or switch statement
 *
 * Syntax: break [<label>]
 * Examples:
 *   break                  // Break from current loop
 *   break@ outerLoop        // Break from labeled loop
 */
breakStatement
    : Break | BreakAt expression
    ;

/**
 * Continue statement - skip to next iteration of loop
 * Jumps to the next iteration of the nearest enclosing loop
 *
 * Syntax: continue [<label>]
 * Examples:
 *   continue               // Continue current loop
 *   continue outerLoop     // Continue labeled loop
 */
continueStatement
    : Continue | ContinueAt expression
    ;

/**
 * Return statement - exit from function with optional value
 * Returns control to caller with optional return value
 *
 * Syntax: return [<expression>]
 * Examples:
 *   return                 // Return void
 *   return result          // Return value
 *   return calculate{x, y} // Return expression result
 */
returnStatement
    : (Return | ReturnAt) expression
    ;

/**
 * Goto statement - unconditional jump to labeled statement
 * Direct control transfer to a labeled location
 *
 * Syntax: goto <label>
 * Examples:
 *   goto cleanup
 *   goto errorHandler
 */
gotoStatement
    : Jump identifier
    ;

// =============================================================================
// VARIABLE OPERATIONS - Assignment and Modification
// =============================================================================

/**
 * Variable operation - all forms of variable assignment and modification
 * Supports simple assignment, compound operations, and increment/decrement
 *
 * Syntax: <assignment> | <compoundAssignment> | <incrementDecrement>
 */
variableOperation
    : assignment
    | lateAssignment
    | lateAssignmentDef
    ;

/**
 * Assignment statement - simple variable value assignment
 * Basic assignment of expression result to variable
 *
 * Syntax: <identifier> = <expression>
 * Examples:
 *   x = 42
 *   result = calculate{a, b}
 *   name = getName{}
 */
assignment
    : (Val | Var | Const)? identifier subTyping Assignment expression
    ;
lateAssignmentDef
    : LateInit (Val | Var | Const) identifier subTyping
    ;
lateAssignment
    : identifier Assignment expression
    ;

// =============================================================================
// ERROR HANDLING APPLICATIONS - Exception Management
// =============================================================================

/**
 * Error handling application - exception throwing and handling constructs
 * Supports throwing exceptions and handling them with try/catch blocks
 *
 * Syntax: <throwStatement> | <tryStatement>
 */
errorHandling
    : throwStatement
    | tryStatement
    ;

/**
 * Throw statement - exception throwing construct
 * Raises an exception with optional error value or message
 *
 * Syntax: throw [<expression>]
 * Examples:
 *   throw                          // Re-throw current exception
 *   throw error{"Invalid input"}   // Throw with message
 *   throw customException{code}    // Throw custom exception
 */
throwStatement
    : Throw expression
    ;

/**
 * Try statement - exception handling construct
 * Executes code with exception handling and optional cleanup
 *
 * Syntax: try <block> [catch <handler>]* [finally <block>]
 * Examples:
 *   try risky{} catch e handle{e}
 *   try operation{} catch IOException e handleIO{e} catch Exception e handleGeneral{e}
 *   try resource{} finally cleanup{}
 */
tryStatement
    : Try loopBody (Catch loopBody)? (Finally loopBody)?
    ;



// =============================================================================
// DEBUGGING/DEVELOPMENT OPERATIONS - Development Support
// =============================================================================

/**
 * Debug operation - debugging and development support statements
 * Supports assertions and debug output for development and testing
 *
 * Syntax: <assertStatement> | <debugStatement>
 */
debugOperation
    : assertStatement
    | debugStatement
    ;

/**
 * Assert statement - runtime assertion checking
 * Validates conditions during execution with optional error messages
 *
 * Syntax: assert <condition> [, <message>]
 * Examples:
 *   assert x > 0
 *   assert isValid{data}, "Data validation failed"
 *   assert length{list} > 0, "List cannot be empty"
 */
assertStatement
    : Assert expression Comma expression
    ;

/**
 * Debug statement - development-time output and logging
 * Provides debug information during development and testing
 *
 * Syntax: debug <expression> | log <level> <message>
 * Examples:
 *   debug variable
 *   log info "Processing started"
 *   debug { "Current state:", state }
 */
debugStatement
    : Annotation Debug statement
    ;

// =============================================================================
// DECLARATION RULES - declaring types, notations, axioms and etc
// =============================================================================
/**
 * Declaration statement - defines new constructs in the language
 * DeduKt supports multiple types of mathematical and computational declarations
 */
declaration
    : typeDeclaration        // Define new types and type relationships
    | contextDeclaration     // Create evaluation scopes
    | notationDeclaration    // Introduce custom syntax
    | functionDeclaration    // Define computational functions
    | operatorDeclaration    // Define mathematical operators
    | structureDeclaration   // Define mathematical structures
    | theoryDeclaration      // Define mathematical theories
    | axiomDeclaration       // Define mathematical axioms
    | ruleDeclaration        // Define transformation rules
    | annotationDeclaration //  Define annotations
    ;

// =============================================================================
// TYPE SYSTEM - Type Declarations and Relationships
// =============================================================================

/**
 * Type declaration - foundation of DeduKt's type system
 * Defines new types with optional constraints and context
 *
 * Syntax: type <name> [<options>] [-> <context>]
 * Examples:
 *   type Vector<T>
 *   type Matrix<T: Numeric> where T <: Real
 *   type Group<T> :: Associative -> { ... }
 */
typeDeclaration
    : Type identifier typeOptions? (Assignment typeContext)?
    ;

/**
 * Type options - modifiers and constraints for type declarations
 * At least one option must be present if typeOptions is used
 * Supports parametric types, constraints, subtyping, and applicability conditions
 */
typeOptions
    : parameters parameterOptions? subTyping? applicability?
    | parameterOptions subTyping? applicability?
    | subTyping applicability?
    | applicability
    ;

/**
 * Type parameters - generic/parametric type support
 * Enclosed in angle brackets, supports dependent types
 *
 * Examples: <T>, <T, U>, <T: Numeric, dim: Integer>
 */
parameters
    : LAngle typeParameters RAngle
    ;

/**
 * List of individual type parameters
 * Supports both simple and dependent (constrained) parameters
 */
typeParameters
    : typeParameter (Comma typeParameter)*
    ;

/**
 * Individual type parameter
 * Can be simple identifier or dependent type with constraints
 */
typeParameter
    : identifier          // Simple: T, U, ElementType
    | dependentType      // Constrained: T: Numeric, dim: Integer
    ;

/**
 * Dependent type - parameter with type constraint
 * Establishes relationship between parameter and its required type
 *
 * Syntax: <name>: <type>
 * Example: T: Numeric, dimension: Integer
 */
dependentType
    : identifier Colon identifier
    ;

/**
 * Parameter constraints - additional restrictions on type parameters
 * Introduced by 'where' keyword, supports subtype and supertype relationships
 */
parameterOptions
    : Where parameterOption+
    ;

/**
 * Individual parameter constraint
 * Defines subtype or supertype relationships for type parameters
 */
parameterOption
    : subtypeOption      // T <: Parent (T is subtype of Parent)
    | superTypeOption    // T >: Child (T is supertype of Child)
    // | conditionalOption  // Future: conditional type constraints
    ;

/**
 * Subtype constraint - parameter must be subtype of specified types
 *
 * Syntax: <param> <: <type1>, <type2>...
 * Example: T <: Numeric, Comparable
 */
subtypeOption
    : identifier SubType commaSeparatedIdentifiers
    ;

/**
 * Supertype constraint - parameter must be supertype of specified types
 *
 * Syntax: <param> >: <type1>, <type2>...
 * Example: T >: Integer, Real
 */
superTypeOption
    : identifier SuperType commaSeparatedIdentifiers
    ;

/**
 * Subtyping declaration - establishes inheritance relationships
 *
 * Syntax: : <parent_types>
 * Example: : Numeric, Comparable
 */
subTyping
    : Colon typeParameters
    ;

/**
 * Applicability conditions - when this type can be used
 * Double colon indicates usage constraints
 *
 * Syntax: :: <conditions>
 * Example: :: Associative, Commutative
 */
applicability
    : DoubleColon typeParameters
    ;

// =============================================================================
// CONTEXT SYSTEM - Scoped Evaluation and Definition
// =============================================================================

/**
 * Context declaration - creates evaluation and definition scopes
 * Contexts are fundamental for step-by-step calculations and chaining results
 * Optional identifier creates named context for later reference
 *
 * Syntax: [context <name>] { <statements> }
 * Examples:
 *   context proof { ... }
 *   { ... }  // Anonymous context
 */
contextDeclaration
    : Context identifier? LBrace statement+ RBrace
    ;

// =============================================================================
// NOTATION SYSTEM - Custom Syntax Definition
// =============================================================================

/**
 * Notation declaration - introduces custom syntax and writing preferences
 * Allows extending DeduKt's syntax for domain-specific mathematical notation
 *
 * Syntax: notation <name> :: <applicability> { <context> }
 * Example: notation matrix_multiply :: Matrix -> { ... }
 */
notationDeclaration
    : Notation identifier applicability Assignment notationContext
    ;

// =============================================================================
// FUNCTION SYSTEM - Computational Units
// =============================================================================

/**
 * Function declaration - defines computational units with input/output
 * Functions are first-class objects in DeduKt's functional programming model
 *
 * Syntax: fun <name> [<params>] (<input_types>) -> <output_types> [:: <applicability>] { <body> }
 * Example: fun add<T: Numeric>(x: T, T) -> T :: Number { ... }
 */
functionDeclaration
    : Fun identifier parameters? functionTypeFormat parameterOptions? applicability? Assignment headlessFunction
    ;

/**
 * Function type signature - defines input and output types
 * Supports multiple inputs and multiple outputs (tuple/multi-return)
 *
 * Syntax: (<inputs>) -> <outputs>
 * Examples:
 *   (Integer, Integer) -> Integer
 *   (Matrix<T>, Vector<T>) -> Vector<T>, Real
 *   (x: Number, y: T) -> R
 */
functionTypeFormat
    : LParen commaSeparatedTypedIdentifiers RParen Arrow (commaSeparatedTypedIdentifiers | commaSeparatedIdentifiers)*
    ;

// =============================================================================
// OPERATOR SYSTEM - Mathematical Operations
// =============================================================================

/**
 * Operator declaration - defines flexible mathematical operations
 * More flexible than functions, supports custom notation and can be embedded in structures/theories
 *
 * Syntax: operator <name> [<type_options>] { <definition> }
 * Example: operator + <T: Group> where T <: Associative { ... }
 */
operatorDeclaration
    : Operator identifier typeOptions? Assignment operatorContext
    ;

// =============================================================================
// STRUCTURE SYSTEM - Mathematical Models
// =============================================================================

/**
 * Structure declaration - defines mathematical structures
 * Containers for related notation, operators, functions, elements and properties
 * Foundation for algebraic and geometric modeling
 *
 * Syntax: structure <name> [<type_options>] { <members> }
 * Example: structure Group<T> where T :: Associative { ... }
 */
structureDeclaration
    : Structure identifier typeOptions? Assignment structureContext
    ;

// =============================================================================
// THEORY SYSTEM - Unified Mathematical Frameworks
// =============================================================================

/**
 * Theory declaration - defines unified mathematical frameworks
 * Combines multiple structures and their relationships
 * Provides high-level abstraction for complex mathematical systems
 *
 * Syntax: theory <name> [<type_options>] { <framework> }
 * Example: theory LinearAlgebra<Field> :: VectorSpace { ... }
 */
theoryDeclaration
    : Theory identifier typeOptions? Assignment theoryContext
    ;

// =============================================================================
// AXIOM SYSTEM - Mathematical Rules and Properties
// =============================================================================

/**
 * Axiom declaration - defines mathematical rules for specific object types
 * Axioms are foundational rules that cannot be proven within the system
 * Applied within structures to establish mathematical properties
 *
 * Syntax: axiom <name> [<type_options>] { <rule_definition> }
 * Example: axiom associativity<T: Group> :: Associative { ... }
 */
axiomDeclaration
    : Axiom identifier typeOptions? Assignment axiomContext
    ;

// =============================================================================
// RULE SYSTEM - Symbolic Transformations
// =============================================================================

/**
 * Rule declaration - defines symbolic transformation rules
 * More permissive than axioms, used for function development and symbolic manipulation
 * Can transform one statement/expression into another based on pattern matching
 *
 * Syntax: rule <name> { <transformation_logic> }
 * Example: rule distribute_multiplication { a * (b + c) -> a * b + a * c }
 */
ruleDeclaration
    : Rule identifier ruleContext
    ;


// =============================================================================
// Annotation SYSTEM - wrapping context in @
// =============================================================================
/**
 * Annotation declaration - defines metadata and directives for other declarations
 * Provides compile-time information, optimization hints, and behavioral modifiers
 * Can be applied to types, functions, structures, etc.
 *
 * Syntax: annotate <name> [<type_options>] { <annotation_definition> }
 * Examples:
 *   annotate @inline { inlining behavior }
 *   annotate @deprecated<T> where T :: Deprecated {  deprecation info }
 *   annotate @complexity :: O(n) { complexity analysis  }
 *   annotate @proof_required {  requires formal proof  }
 *   annotate @experimental {  experimental feature  }
 */
annotationDeclaration
    : At identifier typeOptions? (Assignment annotationContext)?
    ;

/**
 * Annotation-specific context - defines annotation behavior and metadata
 * Contains annotation processing rules and associated data
 */
annotationContext
    : LBrace statement* RBrace
    ;

// =============================================================================
// CONTEXT DEFINITIONS - Specialized Context Bodies
// =============================================================================

/**
 * Generic function body - basic statement container
 * Used for general-purpose scoping and evaluation
 */
headlessFunction
    : LBrace statement*  returnable RBrace
    ;

/**
* Returnable is an statement that returns something. it can return another headless function, or a canonical expression
*/
returnable
    : Return expression
    ;

/**
 * Type-specific context - contains type-related definitions
 * May include type constraints, relationships, and properties
 */
typeContext
    : LBrace statement* RBrace
    ;

/**
 * Notation-specific context - defines custom syntax rules
 * Contains syntax transformation rules and precedence definitions
 */
notationContext
    : LBrace statement* RBrace
    ;


/**
 * Operator-specific context - defines operator behavior
 * Contains operator implementation, precedence, and associativity rules
 */
operatorContext
    : LBrace statement* RBrace
    ;

/**
 * Structure-specific context - contains structure members
 * Includes elements, operations, properties, and internal relationships
 */
structureContext
    : LBrace statement* RBrace
    ;

/**
 * Theory-specific context - contains theory framework
 * Includes multiple structures, their relationships, and unified properties
 */
theoryContext
    : LBrace statement* RBrace
    ;

/**
 * Axiom-specific context - contains axiom definition
 * Includes the fundamental rule and its applicability conditions
 */
axiomContext
    : LBrace statement* RBrace
    ;

/**
 * Rule-specific context - contains transformation rules
 * Includes pattern matching conditions and transformation logic
 */
ruleContext
    : LBrace statement* RBrace
    ;


// =============================================================================
// UTILITY RULES - Common Patterns and Collections
// =============================================================================

/**
 * Comma-separated list of identifiers
 * Used for parameter lists, import lists, constraint lists, etc.
 *
 * Example: x, y, z
 */
commaSeparatedIdentifiers
    : identifier (Comma identifier)*
    ;

/**
 * Comma-separated list of typed identifiers (dependent types)
 * Used for function parameters, structured type definitions, etc.
 *
 * Example: x: Integer, y: Real, matrix: Matrix<T>
 */
commaSeparatedTypedIdentifiers
    : dependentType (Comma dependentType)*
    ;

/**
 * Unified identifier - supports all identifier types from lexer
 * Provides flexibility for naming conventions across different domains
 *
 *
 */
identifier
    : LatexStyleIdentifier
    | SimpleIdentifier
    | MathematicalUnicodeFamily
    ;
// TODO: Literals should contains Strings, Numbers and Identifiers
literal
    : identifier
    | boolean
    | Number
    | StringLiteral
    ;
boolean
    : True
    | False
    ;
