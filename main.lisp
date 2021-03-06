(defun mu-run (form &optional (env nil) (write-env (car (last env))))
  (if (atom form)
      (if (and (symbolp form) (not (keywordp form)))
	  (if env
	      (let ((result (mu-run (list (car env) (list #'mu-quote form)) env write-env)))
		(if (eql result :error)
		    (mu-run form (cdr env) write-env)
		    result))
	      :error)
	  form)
      (let ((action (mu-run (car form) env write-env))
	    (args (cdr form)))
	(if (functionp action)
	    (funcall action args env write-env)
	    (if (hash-table-p action)
		(gethash (mu-run (car args) env write-env) action :error)
		:error)))))

(defun mu-quote (args env write-env)
  (car args))

(defun mu-if (args env write-env)
  (if (mu-run (car args) env write-env)
      (mu-run (cadr args) env write-env)
      (mu-run (caddr args) env write-env)))

(defun mu-function (args env write-env)
  (let ((params (car args))
	(body (cadr args)))
    (lambda (a e we)
      (let ((params-env (make-hash-table)))
	(mapcar (lambda (x y) (setf (gethash x params-env) (mu-run y e we))) params a)
	(mu-run body (cons params-env env) we)))))

(defun mu-macro (args env write-env)
  (let ((params (car args))
	(body (cadr args)))
    (lambda (a e we)
      (let ((params-env (make-hash-table)))
	(mapcar (lambda (x y) (setf (gethash x params-env) y)) params a)
	(mu-run (mu-run body (cons params-env env) we) e we)))))

(defun mu-pack (args env write-env)
  (car (last (mapcar (lambda (x) (mu-run x env write-env)) args))))

(defun mu-def (args env write-env)
  (let ((we (caddr args)))
    (if (not we)
	(setf we write-env)
	(setf we (mu-run we env write-env)))
    (setf (gethash (mu-run (car args) env write-env) we) (mu-run (cadr args) env write-env))))

(defun mu-define (args env write-env)
  (let ((we (caddr args)))
    (if (not we)
	(setf we write-env)
	(setf we (mu-run we env write-env)))
    (setf (gethash (car args) we) (mu-run (cadr args) env write-env))))

(defun s (var val env)
  (if env
      (let ((e (car env)))
	(if (not (eql (gethash var e :error) :error))
	    (setf (gethash var e) val)
	    (s var val (cdr env))))))

(defun mu-set (args env write-env)
  (let ((var (mu-run (car args) env write-env))
	(val (mu-run (cadr args) env write-env)))
    (s var val env)))

(defun mu-setq (args env write-env)
  (let ((var (car args))
	(val (mu-run (cadr args) env write-env)))
    (s var val env)))

(defun mu-let (args env write-env)
  (let ((local-env (make-hash-table)))
    (mapcar (lambda (x)
	      (setf (gethash (car x) local-env) (mu-run (cadr x) env write-env)))
	    (car args))
    (mu-run (cadr args) (cons local-env env) write-env)))

(defun mu-read-envrs (args env write-env)
  env)

(defun mu-envr (args env write-env)
  write-env)

(defun mu-basic (args env write-env)
  (global-env))

(defun mu-empty (args env write-env)
  (make-hash-table))

(defun mu-with (args env write-env)
  (let ((e (mapcar (lambda (x) (mu-run x env write-env)) (car args))))
    (mu-run (cadr args) e write-env)))

(defun mu-to (args env write-env)
  (let ((e (mu-run (car args) env write-env)))
    (mu-run (cadr args) (append env (list e)) e)))

(defun mu-with-append (args env write-env)
  (let ((e (append (mapcar (lambda (x) (mu-run x env write-env)) (car args)) env)))
    (mu-run (cadr args) e write-env)))

(defun mu-eval (args env write-env)
  (mu-run (mu-run (car args) env write-env) env write-env))

(defun mu-print (args env write-env)
  (format t "~D" (mu-run (car args) env write-env)))

(defun mu-println (args env write-env)
  (format t "~D~C" (mu-run (car args) env write-env) #\linefeed))

(defun ld (stream env write-env)
  (let ((form (read stream nil :eof)))
    (if (not (eql form :eof))
	(progn
	  (mu-run form env write-env)
	  (ld stream env write-env)))))

(defun mu-load (args env write-env)
  (with-open-file (stream (mu-run (car args) env write-env))
    (ld stream env write-env)))

(defun muify (func)
  (lambda (args env write-env)
    (apply func (mapcar (lambda (x) (mu-run x env write-env)) args))))

(defmacro env-map (lst)
  `(let ((ge (make-hash-table)))
     (mapcar (lambda (x) (setf (gethash (car x) ge) (eval (cadr x)))) (quote ,lst))
     ge))

(defun global-env ()
  (let ((ge (env-map ((quote #'mu-quote)
		      (*running* t)
		      (if #'mu-if) (t t) (nil nil) (function #'mu-function) (macro #'mu-macro)
		      (pack #'mu-pack) (def #'mu-def) (define #'mu-define) (let #'mu-let)
		      (set #'mu-set) (setq #'mu-setq)
		      (envr #'mu-envr) (basic #'mu-basic) (empty #'mu-empty) (with #'mu-with) (with-append #'mu-with-append) (run #'mu-eval)
		      (load #'mu-load)
		      (to #'mu-to) (read-envrs #'mu-read-envrs)
		      (+ (muify #'+)) (- (muify #'-)) (* (muify #'*)) (/ (muify #'/))
		      (< (muify #'<)) (> (muify #'>)) (= (muify #'=)) (= (muify #'eql))
		      (not (muify #'not))
		      (format (muify #'format)) (print #'mu-print) (println #'mu-println)
		      (first (muify #'car)) (rest (muify #'cdr)) (pair (muify #'cons)) (list (muify #'list))
		      (parse (muify #'read)) (read-char (muify #'read-char)) (peek-char (muify #'peek-char))))))
    (and nil (mu-run `(load "init.lisp") (list ge)))
    (mu-run `(define quit (function () (define *running* nil))) (list ge) ge)
    ge))

(defun mu-loop (env write-env)
  (format t "# ")
  (finish-output)
  (let ((form (mu-run `(parse) env write-env)))
    (format t "~D~C" (mu-run form env write-env) #\linefeed)
    (finish-output)
    (if (mu-run '*running* env write-env)
	(mu-loop env write-env))))

(defun mu-repl ()
  (let ((ge (global-env)))
    (mu-loop (list ge) ge)))
